require File.dirname(__FILE__) + '/../spec_helper'
include ApplicationHelper

describe OtherCostsController do
  describe "Redirects to budget or spend depending on datarequest" do
    before :each do
      @data_request  = Factory(:data_request)
      @organization  = Factory(:organization)
      @user          = Factory(:reporter, :organization => @organization)
      @data_response = @organization.latest_response
      @project       = Factory(:project, :data_response => @data_response)
      @other_cost    = Factory(:other_cost, :project => @project, :data_response => @data_response)
      login @user
    end

    it "redirects to the edit other cost page when Save is clicked" do
      put :update, :other_cost => {:description => "some description"}, :id => @other_cost.id,
        :commit => 'Save', :response_id => @data_response.id
       response.should redirect_to(edit_response_other_cost_path(@data_response.id, @other_cost.id))
     end

     it "redirects to the location classifications page when Save & Add Locations is clicked" do
       @data_request.save
       put :update, :other_cost => { :name => "prewprew" }, :id => @other_cost.id,
         :commit => 'Save & Add Locations >', :response_id => @data_response.id
       response.should redirect_to edit_activity_or_ocost_path(@project.other_costs.first, :mode => 'locations')
     end

     it "redirects to the purpose classifications page when Save & Add Purposes is clicked" do
       @data_request.save
       put :update, :other_cost => { :name => "prewprew" }, :id => @other_cost.id,
         :commit => 'Save & Add Purposes >', :response_id => @data_response.id
       response.should redirect_to edit_activity_or_ocost_path(@project.other_costs.first, :mode => 'purposes')
     end
     it "redirects to the input classifications page when Save & Add Inputs is clicked" do
       @data_request.save
       put :update, :other_cost => { :name => "prewprew" }, :id => @other_cost.id,
         :commit => 'Save & Add Inputs >', :response_id => @data_response.id
       response.should redirect_to edit_activity_or_ocost_path(@project.other_costs.first, :mode => 'inputs')
     end
     it "redirects to the output classifications page when Save & Add Targets is clicked" do
       @data_request.save
       put :update, :other_cost => { :name => "prewprew" }, :id => @other_cost.id,
         :commit => 'Save & Add Targets >', :response_id => @data_response.id
       response.should redirect_to edit_activity_or_ocost_path(@project.other_costs.first, :mode => 'outputs')
     end

     it "correctly updates when an othercost doesn't have a project" do
       @other_cost    = Factory(:other_cost, :project => nil,
                                 :data_response => @data_response)
       put :update, :other_cost => {:description => "some description"}, :id => @other_cost.id,
                                    :commit => 'Save', :response_id => @data_response.id
       flash[:notice].should == "Other Cost was successfully updated."
       response.should redirect_to(edit_response_other_cost_path(@data_response.id, @other_cost.id))
     end

     it "correctly updates when an othercost doesn't have a project or a spend" do
       @other_cost    = Factory(:other_cost, :project => nil,
                                 :data_response => @data_response)
       @other_cost.write_attribute(:spend, nil); @other_cost.save
       put :update, :other_cost => {:description => "some description"}, :id => @other_cost.id,
                                    :commit => 'Save', :response_id => @data_response.id
       flash[:notice].should == "Other Cost was successfully updated."
       response.should redirect_to(edit_response_other_cost_path(@data_response.id, @other_cost.id))
     end

     it "should allow a project to be created automatically on update" do
       #if the project_id is -1 then the controller should create a new project
       put :update, :id => @other_cost.id, :response_id => @data_response.id,
           :other_cost => {:project_id => '-1', :name => @other_cost.name}
       @other_cost.reload
       @other_cost.project.name.should == @other_cost.name
     end

     it "should allow a project to be created automatically on create" do
       #if the project_id is -1 then the controller should create a new project with name
       post :create, :response_id => @data_response.id,
           :other_cost => {:project_id => '-1', :name => "new other_cost", :description => "description"}
       @new_other_cost = Activity.find_by_name('new other_cost')
       @new_other_cost.project.name.should == @new_other_cost.name
     end

     it "should assign the activity to an existing project if a project exists with the same name as the activity" do
       put :update, :id => @other_cost.id, :response_id => @data_response.id,
           :other_cost => {:name => @project.name, :project_id => '-1'}
       @other_cost.reload
       @other_cost.project.name.should == @project.name
     end
   end
end

