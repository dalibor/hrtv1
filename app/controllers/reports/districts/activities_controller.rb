class Reports::Districts::ActivitiesController < Reports::BaseController
  before_filter :load_location

  def index
    @activities        = Activity.top_by_spent_and_budget({
                         :per_page => 25, :page => params[:page],
                         :code_ids => [@location.id], :type => 'district'})
    @spent_pie_values  = DistrictPies::activities(@location, "CodingSpendDistrict")
    @budget_pie_values = DistrictPies::activities(@location, "CodingBudgetDistrict")
  end

  def show
    @activity          = Activity.find(params[:id])
    @spent_pie_values  = DistrictPies::activity_spent_ratio(@location, @activity)
    @budget_pie_values = DistrictPies::activity_budget_ratio(@location, @activity)
    @treemap           = params[:chart_type] == "treemap" || params[:chart_type].blank?
    code_type          = get_code_type_and_initialize(params[:code_type])

    if @treemap
      @code_spent_values  = DistrictTreemaps::treemap(@location, code_type, [@activity], true)
      @code_budget_values = DistrictTreemaps::treemap(@location, code_type, [@activity], false)
    else
      @code_spent_values  = DistrictPies::activity_pie(@location, @activity, code_type, true)
      @code_budget_values = DistrictPies::activity_pie(@location, @activity, code_type, false)
    end

    @charts_loaded  = @spent_pie_values && @budget_pie_values &&
                      @code_spent_values && @code_budget_values

    unless @charts_loaded
      flash.now[:warning] = "Sorry, the Organization hasn't yet properly classified this Activity yet, so some of the charts may be missing!"
    end
  end

  private

    def load_location
      @location = Location.find(params[:district_id])
    end
end
