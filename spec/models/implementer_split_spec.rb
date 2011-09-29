require File.dirname(__FILE__) + '/../spec_helper'

include DelayedJobSpecHelper

describe ImplementerSplit do
  describe "Associations:" do
    it { should belong_to :activity }
    it { should belong_to :organization }
  end

  describe "Attributes:" do
    it { should allow_mass_assignment_of(:activity_id) }
    it { should allow_mass_assignment_of(:organization_id) }
    it { should allow_mass_assignment_of(:budget) }
    it { should allow_mass_assignment_of(:spend) }
    it { should allow_mass_assignment_of(:updated_at) }
  end

  describe "Validations:" do
    it { should validate_numericality_of(:spend) }
    it { should validate_numericality_of(:budget) }

    it "should validate presence of provider_mask" do
      basic_setup_activity
      @split = ImplementerSplit.new(:data_response => @response,
        :activity => @activity)
      @split.save.should == false
      @split.errors.on(:provider_mask).should == "can't be blank"
    end

    describe "implementer uniqueness" do
      # A known rails issue ? http://stackoverflow.com/questions/5482777/rails-3-uniqueness-validation-for-nested-fields-for
      it "should fail when trying to create two sub-activities with the same provider via Activity nested attribute API" do
        pending
        basic_setup_implementer_split
        attributes = {"name"=>"dsf", "start_date"=>"2010-08-02",
          "project_id"=>"#{@project.id}",
          "implementer_splits_attributes"=>
            {"0"=> {"updated_at" => Time.now, "spend"=>"2",
              "activity_id"=>"#{@activity.id}",
              "provider_mask"=>"#{@organization.id}", "budget"=>"4"},
            "1"=> {"updated_at" => Time.now, "spend"=>"3",
              "activity_id"=>"#{@activity.id}",
              "provider_mask"=>"#{@organization.id}", "budget"=>"6"}
            }, "description"=>"adfasdf", "end_date"=>"2010-08-04"}
        @activity.reload
        @activity.update_attributes(attributes).should be_false
        @activity.implementer_splits[1].errors.on(:organization_id).should == "must be unique"
      end

      it "should fail when trying to create two sub-activities with the same provider via Activity nested attribute API" do
        basic_setup_implementer_split
        attributes = {"name"=>"dsf", "start_date"=>"2010-08-02",
          "project_id"=>"#{@project.id}",
          "implementer_splits_attributes"=>
            {"0"=> {"updated_at" => Time.now,"spend"=>"10",
              "id"=>"#{@split.id}",
              "activity_id"=>"#{@activity.id}",
              "provider_mask"=>"#{@organization.id}",
              "budget"=>"20.0"},
            "1"=> {"updated_at" => Time.now, "spend"=>"30",
              "activity_id"=>"#{@activity.id}",
              "provider_mask"=>"#{@organization.id}", "budget"=>"40.0"}
            }, "description"=>"adfasdf", "end_date"=>"2010-08-04"}
        @activity.reload
        @activity.update_attributes(attributes).should be_false
        @activity.errors.full_messages.should include("Duplicate Implementers")
      end

      it "should enforce uniqueness via ImplementerSplit api" do
        basic_setup_implementer_split
        @split1 = Factory(:implementer_split, :activity => @activity,
          :organization => @organization)
        @split1.should_not be_valid
        @split1.errors.on(:organization_id).should == "must be unique"
      end
    end
  end

  describe "Custom validations" do
    before :each do
      basic_setup_activity
    end

    it "should validate Expenditure and/or Budget is present if nil" do
      @split = ImplementerSplit.new(:activity => @activity,
                 :budget => nil, :spend => nil)
      @split.save.should == false
      @split.errors.on(:spend).should include(' and/or Budget must be present')
    end

    it "should validate Expenditure and/or Budget is present if blank" do
      @split = ImplementerSplit.new(:activity => @activity,
                  :budget => "", :spend => "")
      @split.save.should == false
      @split.errors.on(:spend).should include(' and/or Budget must be present')
    end

    it "should fail when trying to create a split without spend/budget via Activity API " do
      attributes = {"name"=>"dsf", "start_date"=>"2010-08-02", "project_id"=>"#{@project.id}",
        "implementer_splits_attributes"=>
          {"0"=> {"updated_at" => Time.now, "spend"=>"", "budget"=>"",
            "activity_id"=>"#{@activity.id}",
            "provider_mask"=>"#{@organization.id}"},
          }, "description"=>"adfasdf", "end_date"=>"2010-08-04"}
      @activity.reload
      @activity.update_attributes(attributes).should be_false
      @activity.implementer_splits[0].errors.on(:spend).should == ' and/or Budget must be present'
    end

    it "should fail when trying to create a split without spend/budget via Activity API " do
      attributes = {"name"=>"dsf", "start_date"=>"2010-08-02", "project_id"=>"#{@project.id}",
        "implementer_splits_attributes"=>
          {"0"=> {"updated_at" => Time.now, "spend"=>"", "budget"=>"",
            "activity_id"=>"#{@activity.id}",
              "provider_mask"=>"#{@organization.id}"},
          }, "description"=>"adfasdf", "end_date"=>"2010-08-04"}
      @activity.reload
      @activity.update_attributes(attributes).should be_false
      @activity.implementer_splits[0].errors.on(:spend).should == ' and/or Budget must be present'
    end

    it "should only update splits via Activity API if updated_at is set" do
      attributes = {"name"=>"dsf", "start_date"=>"2010-08-02", "project_id"=>"#{@project.id}",
        "implementer_splits_attributes"=>
          {"0"=> {"spend"=>"0", "budget"=>"0",
            "activity_id"=>"#{@activity.id}",
            "provider_mask"=>"#{@organization.id}"},
          }, "description"=>"adfasdf", "end_date"=>"2010-08-04"}
      @activity.reload
      @activity.update_attributes(attributes).should be_true
    end

    it "should validate one OR the other" do
      @split = ImplementerSplit.new(:activity => @activity,
                  :budget => nil, :spend => "123.00", :organization => @organization)
      @split.save.should == true
    end
  end

  describe "#budget= and #spend=" do
    before :each do
      basic_setup_activity
      @split = Factory.build(:implementer_split, :activity => @activity)
    end

    it "allows nil value" do
      @split.budget = @split.spend = nil
      @split.budget.should == nil
      @split.spend.should == nil
    end

    it "rounds up to 2 decimals" do
      @split.budget = @split.spend = 10.12745
      @split.budget.to_f.should == 10.13
      @split.spend.to_f.should == 10.13
    end

    it "rounds down to 2 decimals" do
      @split.budget = @split.spend = 10.12245
      @split.budget.to_f.should == 10.12
      @split.spend.to_f.should == 10.12
    end
  end

  describe "saving sub activity updates the activity" do
    before :each do
      basic_setup_activity
    end

    it "should update the spend field on the parent activity" do
      @split = Factory.build :implementer_split, :activity => @activity,
        :spend => 74, :organization => @organization
      @split.save; @activity.reload; @activity.save
      @activity.spend.to_f.should == 74
    end

    it "should update the budget field on the parent activity" do
      @split = Factory.build :implementer_split, :activity => @activity,
        :budget => 74, :organization => @organization
      @split.save; @activity.reload;
      @activity.save # this updates the cache
      @activity.budget.to_f.should == 74
    end
  end

  describe "methods:" do
    before :each do
      donor          = Factory(:donor, :name => 'Donor')
      ngo            = Factory(:ngo,   :name => 'Ngo')
      @location      = Factory(:location, :name => "tehlocation")
      @implementer   = Factory(:ngo,   :name => 'Implementer', :location => @location)
      @data_request  = Factory(:data_request, :organization => donor)
      @response      = ngo.latest_response
      project        = Factory(:project, :data_response => @response)
      @activity      = Factory(:activity, :name => 'Activity 1',
                         :data_response => @response, :provider => ngo, :project => project)
      # @sa            = Factory(:sub_activity, :activity => @activity,
      #                   :data_response => @response, :budget => 100, :spend => 100,
      #                   :provider => @implementer)
      @sa = Factory.build :implementer_split, :activity => @activity,
        :budget => 100, :spend => 100, :organization => @implementer
      @sa.save
      @activity.reload
      @activity.save
    end

    it "should return code assignments for all types of codings" do
      @location = Factory(:location, :short_display => 'Location 1')
      @implementer.location = @location
      CodingBudget.update_classifications(@activity, { Factory(:mtef_code).id => 10 })
      CodingBudgetCostCategorization.update_classifications(@activity, {
        Factory(:cost_category_code).id => 10 })
      CodingSpend.update_classifications(@activity, { Factory(:mtef_code).id => 20 }) # 20%
      CodingSpendCostCategorization.update_classifications(@activity, {
        Factory(:cost_category_code).id => 20 })
      run_delayed_jobs
      @sa.code_assignments[0].cached_amount.to_f.should == 10
      @sa.code_assignments[0].type.should == 'CodingBudget'
      @sa.code_assignments[1].cached_amount.to_f.should == 10
      @sa.code_assignments[1].type.should == 'CodingBudgetCostCategorization'
      @sa.code_assignments[2].cached_amount.to_f.should == 100
      @sa.code_assignments[2].type.should == 'CodingBudgetDistrict'
      @sa.code_assignments[3].cached_amount.to_f.should == 20
      @sa.code_assignments[3].type.should == 'CodingSpend'
      @sa.code_assignments[4].cached_amount.to_f.should == 20
      @sa.code_assignments[4].type.should == 'CodingSpendCostCategorization'
      @sa.code_assignments[5].cached_amount.to_f.should == 100
      @sa.code_assignments[5].type.should == 'CodingSpendDistrict'
    end

    it "caches sub activities count" do
      @implementer2 = Factory(:organization, :location => Factory(:location))
      @implementer_split2 = Factory(:sub_activity, :activity => @activity,
                        :organization => @implementer2,:budget => 4)
      @activity.reload.sub_activities_count.should == 2
      # @response.reload.sub_activities_count.should == 2
      @implementer3 = Factory(:organization, :location => Factory(:location))
      @implementer_split3 = Factory :implementer_split, :activity => @activity,
        :budget => 4, :organization => @implementer3
      # @implementer_split3 = Factory(:sub_activity, :activity => @activity,
      #                   :provider => @implementer3, :data_response => @response, :budget => 4)
      # @response.reload.sub_activities_count.should == 3
      @activity.reload.sub_activities_count.should == 3
    end

    [:budget_district_coding_adjusted, :spend_district_coding_adjusted].each do |method|
      describe "#{method.to_s}" do
        before :each do
          @field = :budget
          @coding = :coding_budget
          @district_coding = :coding_budget_district
          @input_coding = :coding_budget_cost_categorization
          if method == :spend_district_coding_adjusted
            @field = :spend
            @coding = :coding_spend
            @district_coding = :coding_spend_district
            @input_coding = :coding_spend_cost_categorization
          end
        end

        describe "#{@coding}" do
          it "should return adjusted activity code_assignments" do
            klass = @coding.to_s.camelcase.constantize
            klass.update_classifications(@activity, { Factory(:mtef_code).id => 10 })
            run_delayed_jobs
            @sa.send(@coding).length.should == 1
            @sa.send(@coding)[0].cached_amount.to_f.should == 10
            @sa.send(@coding)[0].type.should == @coding.to_s.camelcase
          end
        end

        describe "#{@input_coding}" do
          it "should return adjusted activity code_assignments" do
            Factory(@input_coding, :activity => @activity, :amount => 10, :cached_amount => 10)
            @sa.send(@input_coding).length.should == 1
            @sa.send(@input_coding)[0].cached_amount.to_f.should == 10
            @sa.send(@input_coding)[0].type.should == @input_coding.to_s.camelcase
          end
        end

        it "should return autogenerated code assignments when #{@field} has an amount and sub_activity has 1 location" do
          autosplit = @sa.send(method)[0]
          autosplit.cached_amount.to_f.should == 100
          autosplit.code.should == @location
          autosplit.type.should == @district_coding.to_s.camelcase #e.g. CodingSpendDistrict
        end
      end
    end

    ### Shared examples for the next part

    shared_examples_for "an autosplit that equals the sub-activity total" do
      it "returns adjusted total equal to the SubAct's actual #{@amount_sym.to_s}" do
        @implementer_split.send(@district_adjust_method_sym).inject(0) do |sum, ca|
          sum += ca.cached_amount
        end.to_f.should == @implementer_split.send(@amount_sym).to_f
      end
    end

    shared_examples_for "an autosplit for a single location" do
      it "returns adjusted coding split (for #{@amount_sym.to_s}) using only the Implementer location" do
        autosplit = @implementer_split.send(@district_adjust_method_sym)
        autosplit.length.should == 1
        ca = autosplit[0]
        ca.code.should == @location
        ca.cached_amount.to_f.should == 100
        ca.type.should == @coding_class
      end
    end

    [ [:budget, :coding_budget_district, 'CodingBudgetDistrict', :budget_district_coding_adjusted],
      [:spend, :coding_spend_district, 'CodingSpendDistrict', :spend_district_coding_adjusted]
    ].each do |amount_sym, coding_sym, coding_class, district_adjust_method_sym|
      describe "#{district_adjust_method_sym.to_s}:" do
        before :each do
          @district_adjust_method_sym = district_adjust_method_sym # then we can use shared_examples
          @amount_sym = amount_sym # then we can use shared_examples
          @coding_class = coding_class # then we can use shared_examples
          @implementer_split = @sa
        end

        context "without any existing location splits (code assignments):" do
          # this method, it seems, is multi-purpose.
          #   1) if no coding split has been done, it derives one from your sub-activities
          #     (assumes each implementer has a single location)
          #   2) if a coding split has been done... well...

          context "implementer without location:" do # edge case
            it "should do nothing if implementer has no location" do
              @implementer.location = nil
              @implementer.save!
              autosplit = @implementer_split.send(@district_adjust_method_sym)
              autosplit.should be_empty
            end
          end

          context "implementer with a location:" do
            context "with no existing Location split:" do
              it_should_behave_like "an autosplit for a single location"
              it_should_behave_like "an autosplit that equals the sub-activity total"
            end

            context "with one location coded in Activity Location Split:" do
              it_should_behave_like "an autosplit for a single location"
              it_should_behave_like "an autosplit that equals the sub-activity total"
            end

            context 'with other existing sub-activities:' do
              # this is to highlight that the Implementer-Split (sub activity) does not care about
              # other IS's
              # it should always just return its own ratio to the activity
              before :each do
                @implementer2  = Factory(:ngo,   :name => 'Implementer2')
                @implementer_split2 = Factory(:sub_activity, :activity => @activity,
                                  :organization => @implementer2,
                                  amount_sym => 100)
              end

              it "should not care that total of all implementer splits exceeds activity total" do
                @activity.send(@amount_sym).should == 100
                @implementer_split.send(@amount_sym).should == 100
                @implementer_split2.send(@amount_sym).should == 100
                @implementer_split.should be_valid
                @implementer_split2.should be_valid
              end

              it_should_behave_like "an autosplit for a single location"
              it_should_behave_like "an autosplit that equals the sub-activity total"
            end
          end
        end

        context "with existing location splits (code assignments)" do
          before :each do
            @location2 = Factory(:location, :short_display => 'Location 1')
            Factory(coding_sym, :code => @location, :activity => @activity,
              :amount => 40, :cached_amount => 40)
            Factory(coding_sym, :code => @location2, :activity => @activity,
              :amount => 60, :cached_amount => 60)
            @implementer_split.reload
          end

          context "implementer without location:" do
            # it "should do nothing if implementer has no location" do
            #               # this spec contradicts the authors original intention, but it does highlight it's
            #               # highly conditional logic (i.e. inconstency).
            #               # The inconsistency is that it;
            #               #  - returns nothing when there are no implementer locations and no code assignments
            #               #  - returns something when there is no implementer locations and some code assignments
            #               pending
            #             end

            it "for some reason is autosplitting using existing location splits" do
              #FIXME: contradicts the above spec - but spec is added to make sure this API doesnt get
              # broken when its refactored
              #
              # The API it provides is one of generating 'virtual' codes for sub-activities on
              # the fly, instead of persisting the actual split to the database. This behaviour
              # must be deprecated.
              #
              # A better API would be one where
              #  a) the autosplit method is used manually by the user
              #     to ONLY return a suggested set of splits (which are then saved & persisted)
              #  b) whenever the autosplit method is called, it should never look at existing
              #     coding splits (like its doing here). This logic should be moved to another method
              #     if its still needed.
              #
              #
              @implementer.location = nil
              @implementer.save
              autosplit =  @implementer_split.send(@district_adjust_method_sym)
              autosplit[0].code.should == @location
              autosplit[0].cached_amount.to_f.should == 40
              autosplit[1].code.should == @location2
              autosplit[1].cached_amount.to_f.should == 60
            end
          end
        end
      end
    end
  end

  it "should respond to organization_name" do
    basic_setup_implementer_split
    @split.organization_name.should == @organization.name
  end

  it "should return provider_mask as the org id" do
    org = Factory.build :organization
    split = Factory.build :implementer_split, :organization => org
    split.provider_mask.should == org.id
  end

  it "should support old provider/implementer API" do
    pending
  end

end