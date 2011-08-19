require 'set'
class ProjectsController < Reporter::BaseController
  SORTABLE_COLUMNS = ['name', 'spend', 'budget']

  inherit_resources
  helper_method :sort_column, :sort_direction
  before_filter :load_response
  before_filter :strip_commas_from_in_flows, :only => [:create, :update]
  belongs_to :data_response, :route_name => 'response', :instance_name => 'response'
  before_filter :warn_if_not_current_request, :only => [:index, :new, :edit]


  def index
    scope = @response.projects.scoped({})
    scope = scope.scoped(:conditions => ["UPPER(name) LIKE UPPER(:q)",
                                         {:q => "%#{params[:query]}%"}]) if params[:query]
    @projects = scope.paginate(:page => params[:page], :per_page => 10,
                               :order => "#{sort_column} #{sort_direction}",
                               :include => :activities)

    @comment = Comment.new
    @comment.commentable = @response
    @comments = Comment.on_all([@response.id]).roots.paginate :per_page => 20,
                                                :page => params[:page],
                                                :order => 'created_at DESC'
    
    @project = Project.new(:data_response => @response)                                            
    
    @activity = Activity.new
    @activity.project = @response.projects.find_by_id(params[:project_id])
    @activity.provider = current_user.organization
    
    @other_cost = OtherCost.new
    @other_cost.project = @response.projects.find_by_id(params[:project_id]) if params[:project_id]
    @other_cost.data_response = @response
  end

  def edit
    load_comment_resources(resource)
    edit!
  end

  def create
    @project = Project.new(params[:project].merge(:data_response => @response))
    create! do |success, failure|
      success.html { redirect_to edit_response_project_url(@response, @project) }
    end
  end

  def update
    puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    p params
    puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    success = FundingFlow.create_flows(params)
    update! do |success, failure|
      success.html {
        flash[:error] = "We were unable to save your funding flows, please check your data and try again" if !success
        redirect_to edit_response_project_url(@response, @project)
      }
      failure.html do
        load_comment_resources(resource)
        render :action => 'edit'
      end
    end
  end

  def bulk_edit
    @projects = @response.projects
  end

  def bulk_update
    success = FundingFlow.create_flows(params)
    flash[:notice] = "Your projects have been successfully updated"
    redirect_to response_projects_url
  end

  def download_template
    template = Project.download_template
    send_csv(template, 'projects_template.csv')
  end

  def export
    template = Activity.download_template(@response, @response.activities)
    send_csv(template, "all_activities.csv")
  end

  def download_workplan
    filename = "#{@response.organization.name.split.join('_').downcase.underscore}_workplan.csv"
    send_csv(Reports::OrganizationWorkplan.new(@response).csv, filename)
  end

  def create_from_file
    begin
      if params[:file].present?
        doc = FasterCSV.parse(params[:file].open.read, {:headers => true})
        if doc.headers.to_set == Project::FILE_UPLOAD_COLUMNS.to_set
          saved, errors = Project.create_from_file(doc, @response)
          flash[:notice] = "Created #{saved} of #{saved + errors} projects successfully"
        else
          flash[:error] = 'Wrong fields mapping. Please download the CSV template'
        end
      else
        flash[:error] = 'Please select a file to upload'
      end
    rescue
      flash[:error] = "There was a problem with your file. Did you use the template and save it after making changes as a CSV file instead of an Excel file? Please post a problem at <a href='https://hrtapp.tenderapp.com/kb'>TenderApp</a> if you can't figure out what's wrong."
      redirect_to response_projects_path(@response)
    end
  end

  protected

    def sort_column
      SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "name"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end

    def begin_of_association_chain
      @response
    end

    def strip_commas_from_in_flows
      if params[:project].present? && params[:project][:in_flows_attributes].present?
        in_flows = params[:project][:in_flows_attributes]
        in_flows.each_pair do |id, in_flow|
          [:spend, :spend_q4_prev, :spend_q1, :spend_q2, :spend_q3, :spend_q4, :budget, :budget_q4_prev, :budget_q1, :budget_q2, :budget_q3, :budget_q4].each do |field|
            in_flows[id][field] = convert_number_column_value(in_flows[id][field])
          end
        end
      end
    end

    def convert_number_column_value(value)
      if value == false
        0
      elsif value == true
        1
      elsif value.is_a?(String)
        if (value.blank?)
          nil
        else
          value.gsub(",", "")
        end
      else
        value
      end
    end
end
