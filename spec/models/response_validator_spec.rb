require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../helpers/response_validation_helper'

describe DataResponse do #validations
  before :each do
    @organization = Factory(:organization)
    @request  = Factory.create(:data_request, :organization => @organization)
    @response = @organization.latest_response
    @project  = Factory(:project, :data_response => @response)
    @response.reload
  end

  describe "Request" do
    before :each do
      #need to redo the factories so this test is worth something
      @activity   = Factory(:activity_fully_coded, :data_response => @response, :project => @project)
      @sa         = Factory(:sub_activity, :data_response => @response, :activity => @activity, :budget => 40, :spend => 40)
      @other_cost = Factory(:other_cost_fully_coded, :data_response => @response, :project => @project)
      #@osa        = Factory(:sub_activity, :data_response => @response, :activity => @other_cost, :budget => 40, :spend => 40)
    end

    it "succeeds if activity has spend and budget" do
      @response.activity_amounts_entered?.should == true
    end
    it_should_behave_like "activity spend checker"
    it_should_behave_like "activity budget checker"
    #it_should_behave_like "coded Activities checker" TODO: enable when we get factories working
    it_should_behave_like "coded OtherCosts checker"
  end

  describe "project linking" do
    before :each do
      @organization    = Factory(:organization)
      @request         = Factory(:data_request, :organization => @organization)
      @funder_response = @organization.latest_response
      @funder_project  = Factory(:project, :data_response => @funder_response)
    end

    it "succeeds if projects are linked" do
      #TODO link the projects
      funder = Factory(:funding_source, :to => @project.organization,
        :project => @project,
        :from => @funder_response.organization,
        :project_from_id => @funder_project.id)
      @response.projects_linked?.should == true
    end

    it "fails if no projects exist to link" do
      @response.projects.delete_all
      @response.reload
      @response.projects_linked?.should == false
    end

    it "fails if projects not linked" do
      funder = Factory(:funding_source, :to => @project.organization,
        :project => @project,
        :from => @funder_response.organization)
      @response.projects_linked?.should == false
    end
  end

  describe "ready to submit" do
    before :each do
      @activity        = Factory(:activity_budget_spend_coded, :data_response => @response,
                                 :project => @project)
      @sa              = Factory(:sub_activity, :activity => @activity, 
                                 :data_response => @response, :budget => 100, :spend => 80)

      @activity.save
      @other_cost      = Factory(:other_cost_fully_coded, :data_response => @response,
                                 :project => @project)
      @funder_org      = Factory(:organization)
      @request         = Factory(:data_request, :organization => @organization)
      @funder_response = @organization.latest_response
      @funder_project  = Factory(:project, :data_response => @funder_response)
      @funder = Factory(:funding_flow, :to => @project.organization,
        :project => @project,
        :from => @funder_org,
        :project_from_id => @funder_project.id,
        :budget => 100, :spend => 80)
    end

    it "is OK if everything is entered" do
      @response.stub(:uncoded_activities) { [] }
      @response.projects_entered?.should == true
      @response.projects_linked?.should == true
      @response.activity_amounts_entered?.should == true
      @response.activities_coded?.should == true
      @response.other_costs_coded?.should == true
      @response.projects_have_activities?.should == true
      @response.projects_have_other_costs?.should == true
      @response.projects_and_funding_sources_have_matching_budgets?.should == true
      @response.projects_and_funding_sources_have_correct_spends?.should == true
      @response.ready_to_submit?.should == true
    end

    it "allows submit if everything is coded" do
      @response.stub(:uncoded_activities) { [] }
      @response.submit!.should == true
    end

    context "projects not linked" do
      before :each do
        @funder.project_from_id = nil; @funder.save
      end

      it "succeeds if request not in final review" do
        @response.stub(:uncoded_activities) { [] }
        @request.final_review = false; @request.save; @response.reload
        @response.ready_to_submit?.should == true
      end

      it "fails if in final review " do
        @request.final_review = true; @request.save; @funder_response.reload
        @funder_response.ready_to_submit?.should == false
      end
    end

    it "disallows submit! if not complete" do
      @activity.destroy
      @response.submit!.should == false
    end

    it "fails if there are no activities" do
      @activity.destroy
      @response.activities_coded?.should == false
      @response.ready_to_submit?.should == false
    end

    it "fails if there are uncoded activities" do
      activity2 = Factory(:activity, :data_response => @response, :project => @project)
      sa = Factory(:sub_activity, :data_response => @response, :activity => activity2, :budget => 54)
      @response.activities_coded?.should == false
      @response.ready_to_submit?.should == false
    end

    it "fails if an activity is missing a coding split" do
      cs = @activity.coding_spend.first
      @activity.coding_budget_valid = false; @activity.save; @activity.reload
      @response.uncoded_activities.should have(1).item
      @response.activities_coded?.should == false
      @response.ready_to_submit?.should == false
    end

    it "fails if there are uncoded other costs" do
      cs = @other_cost.coding_spend.first
      sa = Factory(:sub_activity, :data_response => @response, :activity => @other_cost, :budget => 54)
      @other_cost.coding_budget_valid = false; @other_cost.save; @other_cost.reload
      @response.other_costs_coded?.should == false
      @response.ready_to_submit?.should == false
    end
  end

  describe "#projects_and_funding_sources_have_matching_budgets?" do
    context "when no projects entered" do
      before :each do
        @funder1       = Factory.create(:organization)
        @funder2       = Factory.create(:organization)
        @implementer   = Factory.create(:organization)
        @impl_response = @implementer.latest_response
      end

      it "succeeds if no projects entered" do
        @impl_response.projects_and_funding_sources_have_matching_budgets?.should == true
      end
    end

    context "when projects entered" do
      before :each do
        @funder1       = Factory.create(:organization)
        @funder2       = Factory.create(:organization)
        @implementer   = Factory.create(:organization)
        @impl_response = @implementer.latest_response
        @project       = Factory.create(:project, :data_response => @impl_response)
        @activity      = Factory(:activity, :project => @project, :data_response => @impl_response)
        @sa            = Factory(:sub_activity, :activity => @activity, 
                                 :data_response => @impl_response, :budget => 10000)
        @project.reload
      end

      it "is true when budget in flow equals to project budget" do
        Factory.create(:funding_flow, :from => @funder1, :to => @implementer,
                       :project => @project, :budget => 10000)
        @impl_response.projects_and_funding_sources_have_matching_budgets?.should == true
      end

      it "is true when sum of budget in flows is equals to funder budget" do
        setup_funder_equal_to_project(:budget)
        @impl_response.projects_and_funding_sources_have_matching_budgets?.should == true
      end

      it "is false when sum of budget in flows are greated than funder budget" do
        setup_funder_more_than_project(:budget)
        @impl_response.projects_and_funding_sources_have_matching_budgets?.should == false
      end

      it "is false when sum of budget in flows are less than funder budget" do
        @impl_response.projects_and_funding_sources_have_matching_budgets?.should == false
      end
    end
  end

  describe "#projects_and_funding_sources_have_correct_spends?" do
    before :each do
      @funder1       = Factory.create(:organization)
      @funder2       = Factory.create(:organization)
      @implementer   = Factory.create(:organization)
      @impl_response = @implementer.latest_response
      @project       = Factory.create(:project, :data_response => @impl_response)
      @activity      = Factory(:activity, :project => @project, :data_response => @impl_response)
      @sub_activity  = Factory(:sub_activity, :activity => @activity, :data_response => @impl_response, :spend => 10000)
    end

    it "is true when spend in flow equals to project spend" do
      Factory.create(:funding_flow, :from => @funder1, :to => @implementer,
                     :project => @project, :spend => 10000)
      @impl_response.projects_and_funding_sources_have_correct_spends?.should == true
    end

    it "is true when sum of spend in flows is equals to funder spend" do
      setup_funder_equal_to_project(:spend)
      @impl_response.projects_and_funding_sources_have_correct_spends?.should == true
    end

    it "is false when sum of spend in flows are greater than funder spend" do
      setup_funder_more_than_project(:spend)
      @impl_response.projects_and_funding_sources_have_correct_spends?.should == false
    end

    it "is false when sum of spend in flows are less than funder spend" do
      setup_funder_less_than_project(:spend)
      @impl_response.projects_and_funding_sources_have_correct_spends?.should == false
    end
  end
end

#assumes project total is 10
def setup_equal_to_project(field)
  setup_project(field,[2000,3000,5000])
end

def setup_more_than_project(field)
  setup_project(field,[2000,3000,10000])
end

def setup_less_than_project(field)
  setup_project(field,[2000,3000,3000])
end

# quick setup a spend/budget(field) with amounts (activity1, activity2, othercost1)
def setup_project(field, amounts)
  Factory.create(:activity, :data_response => @response,
                 :project => @project, field => amounts[0])
  Factory.create(:activity, :data_response => @response,
                 :project => @project, field => amounts[1])
  Factory.create(:other_cost, :data_response => @response,
                 :project => @project, field => amounts[2])
end


#assumes project total is 10
def setup_funder_equal_to_project(field)
  setup_funders(field,[5000,5000])
end

def setup_funder_more_than_project(field)
  setup_funders(field,[5000,6000])
end

def setup_funder_less_than_project(field)
  setup_funders(field,[1000,1000])
end

# quick setup a spend/budget(field) with amounts (funder1, funder2)
def setup_funders(field, amounts)
  Factory.create(:funding_flow, :from => @funder1, :to => @implementer,
   :project => @project, field => amounts[0])
  Factory.create(:funding_flow, :from => @funder2, :to => @implementer,
   :project => @project, field => amounts[1])
end
