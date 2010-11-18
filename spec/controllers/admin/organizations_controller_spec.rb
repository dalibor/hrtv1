require 'spec_helper'

describe Admin::OrganizationsController do

  describe "destroy organization" do
    before :each do
      login(Factory.create(:admin))
    end

    describe "when organization is empty" do
      before :each do
        Organization.stub!(:find).with("1").and_return(@mock_object = mock_model(Organization, :is_empty? => true, :destroy => true))
      end

      it "finds organization" do
        Organization.should_receive(:find).with("1").and_return(@mock_object)
        delete :destroy, :id => "1"
      end

      it "destroys organization" do
        @mock_object.should_receive(:destroy).and_return(true)
        delete :destroy, :id => "1"
      end

      describe 'html format' do
        it "sets flash notice" do
          delete :destroy, :id => "1"
          flash[:notice].should == "Organization was successfully deleted."
        end

        it "redirects to the duplicate_admin_organizations_path" do
          delete :destroy, :id => "1"
          response.should redirect_to(duplicate_admin_organizations_path)
        end
      end

      describe 'js format' do
        it "returns proper json when request is with js format" do
          delete :destroy, :id => "1", :format => "js"
          response.body.should == '{"message":"Organization was successfully deleted."}'
        end

        it "does not redirect" do
          delete :destroy, :id => "1", :format => "js"
          response.should_not be_redirect
        end
      end
    end


    describe "when organization is not empty" do
      before :each do
        Organization.stub!(:find).with("1").and_return(@mock_object = mock_model(Organization, :is_empty? => false, :destroy => true))
      end

      it "finds organization" do
        Organization.should_receive(:find).with("1").and_return(@mock_object)
        delete :destroy, :id => "1"
      end

      it "does not destroys organization" do
        @mock_object.should_not_receive(:destroy)
        delete :destroy, :id => "1"
      end

      describe 'html format' do
        it "sets flash notice" do
          delete :destroy, :id => "1"
          flash[:error].should == "You cannot delete an organization that has users or data associated with it."
        end

        it "redirects to the duplicate_admin_organizations_path" do
          delete :destroy, :id => "1"
          response.should redirect_to(duplicate_admin_organizations_path)
        end
      end

      describe 'js format' do
        it "returns proper json when request is with js format" do
          delete :destroy, :id => "1", :format => "js"
          response.body.should == '{"message":"You cannot delete an organization that has users or data associated with it."}'
        end

        it "does not redirects" do
          delete :destroy, :id => "1", :format => "js"
          response.should_not be_redirect
        end

        it "sets status to :partial_content" do
          delete :destroy, :id => "1", :format => "js"
          response.status.should == "206 Partial Content"
        end
      end
    end

  end
end