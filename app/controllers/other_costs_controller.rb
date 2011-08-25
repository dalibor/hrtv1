class OtherCostsController < Reporter::BaseController
  SORTABLE_COLUMNS = ['description', 'past expenditure', 'current budget']

  inherit_resources
  helper_method :sort_column, :sort_direction
  before_filter :load_response
  before_filter :confirm_activity_type, :only => [:edit]
  before_filter :warn_if_not_classified, :only => [:edit]
  belongs_to :data_response, :route_name => 'response', :instance_name => 'response'

  def new
    self.load_other_cost_new
  end

  def edit
    prepare_classifications(resource)
    load_comment_resources(resource)
    edit!
  end

  def create
    @other_cost = @response.other_costs.new(params[:other_cost])
    if @other_cost.save
      respond_to do |format|
        format.html { success_flash("created"); html_redirect }
        format.js { js_redirect }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.js   { js_redirect }
      end
    end
  end

  def update
    @other_cost = OtherCost.find(params[:id])
    if !@other_cost.am_approved? && @other_cost.update_attributes(params[:other_cost])
     respond_to do |format|
       format.html { success_flash("updated"); html_redirect }
       format.js   { js_redirect }
     end
    else
     respond_to do |format|
       format.html { flash[:error] = ("Other Cost was already approved by #{@other_cost.user.try(:full_name)} " +
                                      "(#{@other_cost.user.try(:email)}) " +
                                      "on #{@other_cost.am_approved_date}") if @other_cost.am_approved?
                     prepare_classifications(resource)
                     load_comment_resources(resource)
                     render :action => 'edit'
                   }
       format.js   { js_redirect }
     end
    end
  end

  def destroy
    destroy! do |success, failure|
      success.html do
        flash[:notice] = 'Other Cost was successfully destroyed'
        redirect_to response_projects_url(@response)
      end
    end
  end

  def download_template
    template = OtherCost.download_template
    send_csv(template, 'other_costs_template.csv')
  end

  def create_from_file
    begin
      if params[:file].present?
        doc = FasterCSV.parse(params[:file].open.read, {:headers => true})
        if doc.headers.to_set == OtherCost::FILE_UPLOAD_COLUMNS.to_set
          saved, errors = OtherCost.create_from_file(doc, @response)
          flash[:notice] = "Created #{saved} of #{saved + errors} other costs successfully"
        else
          flash[:error] = 'Wrong fields mapping. Please download the CSV template'
        end
      else
        flash[:error] = 'Please select a file to upload'
      end

      redirect_to response_other_costs_url(@response)
    rescue
      flash[:error] = "There was a problem with your file. Did you use the template and save it after making changes as a CSV file instead of an Excel file? Please post a problem at <a href='https://hrtapp.tenderapp.com/kb'>TenderApp</a> if you can't figure out what's wrong."
      redirect_to response_other_costs_url(@response)
    end
  end


  private

    def success_flash(action)
      flash[:notice] = "Other Cost was successfully #{action}."
      if params[:other_cost][:project_id] == Activity::AUTOCREATE
        flash[:notice] += "  <a href=#{edit_response_project_path(@response, @other_cost.project)}>Click here</a>
                           to enter the funding sources for the automatically created project."
      end
    end

    def sort_column
      SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "activities.name"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end

    def confirm_activity_type
      @other_cost = OtherCost.find(params[:id])
      return redirect_to edit_response_activity_path(@response, @other_cost) if @other_cost.class.eql? Activity
      return redirect_to edit_response_activity_path(@response, @other_cost.activity) if @other_cost.class.eql? SubActivity
    end

    def prepare_classifications(other_cost)
      # if we're viewing classification 'tabs'
      if ['locations', 'purposes', 'inputs'].include? params[:mode]
        load_klasses :mode
        @budget_coding_tree = CodingTree.new(other_cost, @budget_klass)
        @spend_coding_tree  = CodingTree.new(other_cost, @spend_klass)
        @budget_assignments = @budget_klass.with_activity(other_cost).all.
                                map_to_hash{ |b| {b.code_id => b} }
        @spend_assignments  = @spend_klass.with_activity(other_cost).all.
                                map_to_hash{ |b| {b.code_id => b} }
        # set default to 'my' view if there are code assignments present
        if params[:view].blank?
          params[:view] = @budget_coding_tree.roots.present? ? 'my' : 'all'
        end
      end
    end
end
