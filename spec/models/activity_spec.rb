require File.dirname(__FILE__) + '/../spec_helper'

describe Activity do
  
  describe "creating an activity record" do
    subject { Factory(:activity) }
    
    it { should be_valid }
    it { should have_many :sub_activities }
    it { should have_many :code_assignments }
    it { should have_and_belong_to_many :organizations }
    it { should have_and_belong_to_many :beneficiaries }
    it { should have_and_belong_to_many :locations }
    it { should have_and_belong_to_many :projects }
    it { should belong_to :provider }
  end
  
  describe "assigning an activity to a project" do
    it "should assign to a project" do
      project      = Factory(:project)
      activity     = Factory(:activity)
      project.activities << activity
      project.activities.should have(1).item
      project.activities.first.should == activity      
    end
  end
  
  describe "commenting on an activity" do
    it "should assign to an activity" do
      activity     = Factory(:activity)
      comment      = Factory(:comment, :commentable => activity )
      activity.comments.should have(1).item
      activity.comments.first.should == comment
    end
  end
  
  describe "can show who we provided money to (providers)" do
    context "on a single project" do
      it "should have at least 1 provider" do  
        our_org      = Factory(:organization)
        other_org    = Factory(:organization)
        project      = Factory(:project)
        flow         = Factory(:funding_flow, :from => our_org, 
                                              :to => other_org, 
                                              :project => project,
                                              :data_response => project.data_response)
        activity     = Factory(:activity, { :projects => [project], 
                                            :provider => other_org })
        activity.provider.should == other_org # duh
        activity.projects.should have(1).project         
      end
    end
    
    context "across multiple projects" do
      it "should allow assignment to multiple projects" do
        pending
      end
    end
  end
  
  it "cannot be edited once approved" do
    a = Factory(:activity)
    a.approved.should == nil
    a.approved = true
    a.save!
    a.spend = 2000
    a.save.should == false
  end
  
  describe "finding total spend for strategic objective codes" do
    it "return nothing if no codes assigned to HSSP spend" do
      pending #https://www.pivotaltracker.com/story/show/6115671  
      activity     = Factory(:activity)
      activity.spend_stratobj_coding.should == []
    end
  end

  describe "use budget for expenditure codings" do
    def copy_budget_to_expenditure_check(activity, actual_type, expected_type)
      activity.copy_budget_codings_to_spend([actual_type])
      code_assignments = activity.code_assignments
      code_assignments.length.should == 2
      code_assignments[0].class.to_s.should == actual_type
      code_assignments[1].class.to_s.should == expected_type
    end

    def copy_budget_to_expenditure_check_cached_amount(activity, type, expected_cached_amount)
      activity.copy_budget_codings_to_spend([type])
      code_assignments = activity.code_assignments
      code_assignments[1].cached_amount.should == expected_cached_amount
    end

    it "copies budget for expenditure codings for CodingBudget" do
      activity = Factory(:activity)
      Factory(:coding_budget, :activity => activity)
      copy_budget_to_expenditure_check(activity, 'CodingBudget', 'CodingSpend')
    end

    it "copies budget for expenditure codings for CodingBudgetDistrict" do
      activity = Factory(:activity)
      Factory(:coding_budget_district, :activity => activity)
      copy_budget_to_expenditure_check(activity, 'CodingBudgetDistrict', 'CodingSpendDistrict')
    end

    it "copies budget for expenditure codings for CodingBudgetCostCategorization" do
      activity = Factory(:activity)
      Factory(:coding_budget_cost_categorization, :activity => activity)
      copy_budget_to_expenditure_check(activity, 'CodingBudgetCostCategorization', 'CodingSpendCostCategorization')
    end

    it "deletes existing Spend codes before copying" do
      activity = Factory(:activity)
      Factory(:coding_budget, :activity => activity)
      Factory(:coding_spend, :activity => activity)
      copy_budget_to_expenditure_check(activity, 'CodingBudget', 'CodingSpend')
    end

    it "calculates cached_amount when spend is nil" do
      activity = Factory(:activity, :spend => nil)
      Factory(:coding_budget, :activity => activity)
      expected_cached_value = 0
      copy_budget_to_expenditure_check_cached_amount(activity, 'CodingBudget', expected_cached_value)
    end

    it "calculates cached_amount when spend is 0" do
      activity = Factory(:activity, :spend => 0)
      Factory(:coding_budget, :activity => activity)
      expected_cached_value = 0
      copy_budget_to_expenditure_check_cached_amount(activity, 'CodingBudget', expected_cached_value)
    end

    it "calculates cached_amount when budget is nil" do
      activity = Factory(:activity, :budget => nil)
      Factory(:coding_budget, :activity => activity)
      expected_cached_value = 0
      copy_budget_to_expenditure_check_cached_amount(activity, 'CodingBudget', expected_cached_value)
    end

    it "calculates cached_amount when budget is 0" do
      activity = Factory(:activity, :budget => 0)
      Factory(:coding_budget, :activity => activity)
      expected_cached_value = 0
      copy_budget_to_expenditure_check_cached_amount(activity, 'CodingBudget', expected_cached_value)
    end

    it "calculates spend cached_amount when there is calculated cache amount for budget" do
      activity = Factory(:activity, :budget => 100, :spend => 50)
      ca = Factory(:coding_budget, :activity => activity, :cached_amount => 100)
      expected_cached_value = 50
      copy_budget_to_expenditure_check_cached_amount(activity, 'CodingBudget', expected_cached_value)
    end

    it "calculates spend cached_amount when there is no calculated cache amount for budget and code assigment has percentages" do
      activity = Factory(:activity, :budget => 100, :spend => 50)
      Factory(:coding_budget, :activity => activity, :percentage => 50)
      expected_cached_value = 25
      copy_budget_to_expenditure_check_cached_amount(activity, 'CodingBudget', expected_cached_value)
    end

    it "calculates spend amount when there is amount for budget" do
      activity = Factory(:activity, :budget => 100, :spend => 50)
      Factory(:coding_budget, :activity => activity, :amount => 100, :cached_amount => 100)
      activity.copy_budget_codings_to_spend(['CodingBudget'])
      code_assignments = activity.code_assignments
      code_assignments[1].amount.should == 50
    end

    it "does not calculates spend amount when there is amount for budget and code_assignment amount is nil" do
      activity = Factory(:activity, :budget => 100, :spend => 50)
      Factory(:coding_budget, :activity => activity, :amount => nil, :cached_amount => 100)
      activity.copy_budget_codings_to_spend(['CodingBudget'])
      code_assignments = activity.code_assignments
      code_assignments[1].amount.should == nil
    end

    it "calculates spend percentage when there is percentage for budget" do
      activity = Factory(:activity, :budget => 100, :spend => 50)
      Factory(:coding_budget, :activity => activity, :percentage => 50)
      activity.copy_budget_codings_to_spend(['CodingBudget'])
      code_assignments = activity.code_assignments
      code_assignments[1].percentage.should == 50
    end
  end

  describe "counter cache" do
    context "comments cache" do
      before :each do
        @commentable = Factory.create(:activity)
      end

      it_should_behave_like "comments_cacher"
    end

    it "caches sub activities count" do
      activity = Factory.create(:activity)
      activity.sub_activities_count.should == 0
      Factory.create(:sub_activity, :activity => activity)
      activity.reload.sub_activities_count.should == 1
      Factory.create(:sub_activity, :activity => activity)
      activity.reload.sub_activities_count.should == 2
    end
  end
  
  describe "deep cloning" do
    before :each do
      @activity = Factory(:activity)
      @original = @activity #for shared examples
    end
    
    it "should clone associated code assignments" do
      @ca = Factory(:code_assignment, :activity => @activity)
      save_and_deep_clone
      @clone.code_assignments.count.should == 1
      @clone.code_assignments.first.code.should == @ca.code
      @clone.code_assignments.first.amount.should == @ca.amount
      @clone.code_assignments.first.activity.should_not == @activity
      @clone.code_assignments.first.activity.should == @clone
    end
    
    it "should clone organizations" do
      @orgs = [Factory(:organization), Factory(:organization)]
      @activity.organizations << @orgs
      save_and_deep_clone
      @clone.organizations.should == @orgs
    end
    
    it "should clone beneficiaries" do
      @benefs = [Factory(:beneficiary), Factory(:beneficiary)]
      @activity.beneficiaries << @benefs
      save_and_deep_clone
      @clone.beneficiaries.should == @benefs
    end
    
    it_should_behave_like "location cloner"
  end

end
