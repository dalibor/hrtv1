require File.dirname(__FILE__) + '/../spec_helper'

describe User do

  describe "attributes" do
    it { should allow_mass_assignment_of(:full_name) }
    it { should allow_mass_assignment_of(:email) }
    it { should allow_mass_assignment_of(:username) }
    it { should allow_mass_assignment_of(:password) }
    it { should allow_mass_assignment_of(:password_confirmation) }
    it { should allow_mass_assignment_of(:organization_id) }
    it { should allow_mass_assignment_of(:organization) }
    it { should allow_mass_assignment_of(:organization_ids) }
    it { should allow_mass_assignment_of(:roles) }
  end

  describe "associations" do
    it { should have_many :comments }
    it { should have_many :data_responses }
    it { should belong_to :organization }
    it { should belong_to :current_response }
    it { should have_and_belong_to_many :organizations }
  end

  describe "Validations" do
    subject { Factory(:reporter, :organization => Factory(:organization) ) }
    it { should be_valid }
    it { should validate_presence_of(:username) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:organization_id) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_uniqueness_of(:username).case_insensitive }

    it "validates presence of data_response_id_current" do
      organization = Factory(:organization, :data_responses => [])
      user = Factory.build(:user, :organization => organization, :current_response => nil)
      user.save
      user.errors.on(:data_response_id_current).should include("can't be blank")
    end

    it "cannot assign blank role" do
      user = Factory.build(:reporter, :roles => [])
      user.save
      user.errors.on(:roles).should include('is not included in the list')
    end

    it "cannot assign unexisting role" do
      user = Factory.build(:reporter, :roles => ['admin123'])
      user.save
      user.errors.on(:roles).should include('is not included in the list')
    end
  end

  describe "Callbacks" do
    before :each do
      @dr1 = Factory(:data_response)
      @dr2 = Factory(:data_response)
      @organization = Factory(:organization, :data_responses => [@dr1, @dr2])
    end

    it "assigns current_response to last data_response from the organization" do
      user = Factory.build(:user, :organization => @organization, :current_response => nil)
      user.save
      user.current_response.should == @dr2
    end

    it "does not assign current_response if it already exists" do
      user = Factory.build(:user, :organization => @organization)
      user.save
      user.current_response.should_not == @dr2
    end
  end

  describe "find_by_username_or_email" do
    it "finds user by username" do
      user = Factory(:reporter, :username => 'pink.panter')
      User.find_by_username_or_email('pink.panter').should == user
    end

    it "finds user by email" do
      user = Factory(:reporter, :email => 'pink.panter@gmail.com')
      User.find_by_username_or_email('pink.panter@gmail.com').should == user
    end
  end

  describe "a user can change their current data response" do
    it "it will allow a data response that they have access to" do
      @org = Factory(:organization)
      @user = Factory(:reporter, :organization => @org)
      @data_response = Factory(:data_response, :organization => @user.organization)
      @user.current_response = @data_response
      @user.save.should be_true
    end

    it "will not allow a user to change to a data request that they dont' have access to (ie. doesn't show up for @user.data_responses)" do
      @org = Factory(:organization)
      @user = Factory(:reporter, :organization => @org)
      @data_response = Factory(:data_response, :organization => @user.organization)
      @data_response2 = Factory(:data_response)
      @user.current_response = @data_response
      @user.save.should be_true
    end
  end

  describe "roles" do
    it "is admin when roles_mask = 1" do
      user = Factory(:user, :roles => ['admin'])
      user.roles.should == ['admin']
      user.roles_mask.should == 1
    end

    it "is reporter when roles_mask = 2" do
      user = Factory(:user, :roles => ['reporter'])
      user.roles.should == ['reporter']
      user.roles_mask.should == 2
    end

    it "is admin and reporter when roles_mask = 3" do
      user = Factory(:user, :roles => ['admin', 'reporter'])
      user.roles.should == ['admin', 'reporter']
      user.roles_mask.should == 3
    end

    it "is activity_manager when roles_mask = 4" do
      user = Factory(:user, :roles => ['activity_manager'])
      user.roles.should == ['activity_manager']
      user.roles_mask.should == 4
    end

    it "is admin and activity_manager when roles_mask = 5" do
      user = Factory(:user, :roles => ['admin', 'activity_manager'])
      user.roles.should == ['admin', 'activity_manager']
      user.roles_mask.should == 5
    end

    it "is reporter and activity_manager when roles_mask = 6" do
      user = Factory(:user, :roles => ['reporter', 'activity_manager'])
      user.roles.should == ['reporter', 'activity_manager']
      user.roles_mask.should == 6
    end

    it "is admin, reporter and activity_manager when roles_mask = 7" do
      user = Factory(:user, :roles => ['admin', 'reporter', 'activity_manager'])
      user.roles.should == ['admin', 'reporter', 'activity_manager']
      user.roles_mask.should == 7
    end
  end

  describe "roles= can be assigned" do
    it "can assign 1 role" do
      user = Factory(:reporter)
      user.roles = ['admin']
      user.save
      user.reload.roles.should == ['admin']
    end

    it "can assign 3 roles" do
      user = Factory(:reporter)
      user.roles = ['admin', 'reporter', 'activity_manager']
      user.save
      user.reload.roles.should == ['admin', 'reporter', 'activity_manager']
    end
  end

  describe "role change" do
    it "removed organizations when role is changed from activity_manager to else" do
      org1 = Factory(:organization)
      org2 = Factory(:organization)
      user = Factory(:activity_manager, :organizations => [org1, org2])
      user.roles = ['reporter']
      user.save
      user.organizations.should be_empty
    end
  end

  describe "admin?" do
    it "is admin when roles_mask is 1" do
      user = Factory(:admin, :roles_mask => 1)
      user.admin?.should be_true
    end

    it "is not admin when roles_mask is not 1" do
      user = Factory(:reporter, :roles_mask => 2)
      user.admin?.should be_false
    end
  end

  describe "reporter?" do
    it "is reporter when roles_mask is 2" do
      user = Factory(:reporter, :roles_mask => 2)
      user.reporter?.should be_true
    end

    it "is not reporter when roles_mask is not 1" do
      user = Factory(:admin, :roles_mask => 1)
      user.reporter?.should be_false
    end
  end

  describe "activity_manager?" do
    it "is activity_manager when roles_mask is 3" do
      user = Factory(:activity_manager, :roles_mask => 3)
      user.activity_manager?.should be_true
    end

    it "is not activity_manager when roles_mask is not 3" do
      user = Factory(:admin, :roles_mask => 1)
      user.activity_manager?.should be_false
    end
  end

  describe "name" do
    it "returns full_name if full name is present" do
      user = Factory(:reporter, :full_name => "Pink Panter")
      user.name.should == "Pink Panter"
    end

    it "returns email if full name is nil" do
      user = Factory(:reporter, :full_name => nil, :username => 'pink.panter', :email => 'user@hrtapp.com')
      user.name.should == "pink.panter"
    end

    it "returns email if full name is blank string" do
      user = Factory(:reporter, :full_name => '', :username => 'pink.panter', :email => 'user@hrtapp.com')
      user.name.should == "pink.panter"
    end
  end

  describe "current response/request" do
    before :each do
      @org = Factory :organization
      @response = Factory(:response, :organization => @org)
      @user = Factory(:reporter, :current_response => @response, :organization => @org)
    end

    it "returns the associated request" do
      @user.current_request.should == @response.request
    end
  end

end

# == Schema Information
#
# Table name: users
#
#  id                       :integer         primary key
#  username                 :string(255)
#  email                    :string(255)
#  crypted_password         :string(255)
#  password_salt            :string(255)
#  persistence_token        :string(255)
#  created_at               :timestamp
#  updated_at               :timestamp
#  roles_mask               :integer
#  organization_id          :integer
#  data_response_id_current :integer
#  text_for_organization    :text
#  full_name                :string(255)
#  perishable_token         :string(255)     default(""), not null
#

