class ClassificationsController < Reporter::BaseController
  before_filter :load_data_response

  def edit
    @projects     = @response.projects.find(:all, :order => 'name ASC')
    @coding_tree  = CodingTree.new(Activity.new, params[:id].constantize)
    @codes        = @coding_tree.root_codes
  end

  def update
    @activity = @response.activities.find(params[:activity_id])
    CodeAssignment.update_classifications(@activity, params[:classifications], params[:id])

    respond_to do |format|
      format.html do
        flash[:notice] = 'Health Functions classifications for Expenditure were successfully saved'
        redirect_to edit_response_classification_url(@response, params[:id])
      end
      format.json do
        render :json => {:html => render_to_string(:partial => 'activity_row.html.haml',
                                                   :locals => {
                                                     :project => @activity.project,
                                                     :activity => @activity
                                                   })}
      end
    end
  end

  def destroy
    ca = @response.code_assignments.find(params[:id])
    activity = ca.activity
    klass = ca.class
    ca.destroy
    activity.update_classified_amount_cache(klass)

    render :json => {:status => true}
  end
end
