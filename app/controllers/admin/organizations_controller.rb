require 'set'
class Admin::OrganizationsController < Admin::BaseController
  include ResponseStatesHelper

  SORTABLE_COLUMNS  = ['name', 'raw_type', 'fosaid']
  AVAILABLE_FILTERS = ["All", "Not Yet Started", "Started", "Submitted", "Rejected", "Accepted"]

  ### Inherited Resources
  inherit_resources

  helper_method :sort_column, :sort_direction

  def index
    scope = Organization.scoped({})
    scope = filter_organizations(scope, params[:filter]) if allowed_filter?(params[:filter])
    scope = scope.scoped(:conditions => ["UPPER(organizations.name) LIKE UPPER(:q) OR
                                           UPPER(organizations.raw_type) LIKE UPPER(:q) OR
                                           UPPER(organizations.fosaid) LIKE UPPER(:q)",
                                           {:q => "%#{params[:query]}%"}]) if params[:query]

    @organizations = scope.paginate(:page => params[:page], :per_page => 200,
                    :order => "UPPER(organizations.#{sort_column}) #{sort_direction}")
    @responses = current_request.data_responses
  end

  def show
    @organization = Organization.find(params[:id])

    respond_to do |format|
      format.js {render :partial => 'organization_info'}
    end
  end

  def create
    create! do |success, failure|
      success.html do
        flash[:notice] = "Organization was successfully created"
        redirect_to edit_admin_organization_url(resource)
      end
    end
  end

  def update
    @organization = Organization.find(params[:id])
    @organization.attributes = params[:organization]
    if @organization.save(false)
      flash[:notice] = 'Organization was successfully updated'
      redirect_to edit_admin_organization_url(resource)
    else
      render :edit
    end
  end

  def destroy
    @organization = Organization.find(params[:id])

    # when on fix duplicate organizations page then redirect to :back
    # otherwise redirect to admin organizatoins index  page
    url = request.env['HTTP_REFERER'].to_s.match(/duplicate/) ?
      duplicate_admin_organizations_url : admin_organizations_url

    if @organization.is_empty?
      @organization.destroy
      render_notice("Organization was successfully destroyed.", url)
    else
      render_error("You cannot delete an organization that has users or data associated with it.", url)
    end
  end

  def duplicate
    @organizations_without_users = Organization.without_users.ordered
    @all_organizations = Organization.ordered
  end

  def remove_duplicate
    if params[:duplicate_organization_id].blank? && params[:target_organization_id].blank?
      render_error("Duplicate or target organizations not selected.", duplicate_admin_organizations_path)
    elsif params[:duplicate_organization_id] == params[:target_organization_id]
      render_error("Same organizations for duplicate and target selected.", duplicate_admin_organizations_path)
    else
      duplicate = Organization.find(params[:duplicate_organization_id])
      target = Organization.find(params[:target_organization_id])

      if duplicate.users_count > 0
        render_error("Duplicate organization #{duplicate.name} has users.", duplicate_admin_organizations_path)
      else
        Organization.merge_organizations!(target, duplicate)
        render_notice("Organizations successfully merged.", duplicate_admin_organizations_path)
      end
    end
  end

  def download_template
    template = Organization.download_template
    send_csv(template, 'organization_template.csv')
  end

  def create_from_file
    begin
      if params[:file].present?
        doc = FasterCSV.parse(params[:file].open.read, {:headers => true})
        if doc.headers.to_set == Organization::FILE_UPLOAD_COLUMNS.to_set
          saved, errors = Organization.create_from_file(doc)
          flash[:notice] = "Created #{saved} of #{saved + errors} organizations successfully"
        else
          flash[:error] = 'Wrong fields mapping. Please download the CSV template'
        end
      else
        flash[:error] = 'Please select a file to upload'
      end

      redirect_to admin_organizations_url
    rescue
      flash[:error] = "There was a problem with your file. Did you use the template and save it after making changes as a CSV file instead of an Excel file? Please post a problem at <a href='https://hrtapp.tenderapp.com/kb'>TenderApp</a> if you can't figure out what's wrong."
      redirect_to admin_organizations_url
    end
  end

  private

    def render_error(message, path)
      respond_to do |format|
        format.html do
          flash[:error] = message
          redirect_to path
        end
        format.js do
          render :json => {:message => message}.to_json, :status => :partial_content
        end
      end
    end

    def render_notice(message, path)
      respond_to do |format|
        format.html do
          flash[:notice] = message
          redirect_to path
        end
        format.js do
          render :json => {:message => message}.to_json
        end
      end
    end

    def sort_column
      SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "name"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

    def filter_organizations(scope, filter)
      if filter == 'All'
        scope
      else
        scope.responses_by_states(current_request, [name_to_state(filter)])
      end
    end

    def allowed_filter?(filter)
      AVAILABLE_FILTERS.include?(filter)
    end
end
