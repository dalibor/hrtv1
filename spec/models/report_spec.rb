require File.dirname(__FILE__) + '/../spec_helper'

describe Report do

  describe "creating a record" do
    before :each do
      csv_report  = Reports::UsersByOrganization.new
      csv_report.stub(:csv).and_return('1,1,1')
      Reports::UsersByOrganization.stub(:new).and_return(csv_report)
    end

    it { should validate_presence_of(:key) }
    it { should allow_mass_assignment_of(:key) }
    it { should allow_mass_assignment_of(:csv) }
    it { should allow_mass_assignment_of(:formatted_csv) }

    it "should only accept unique keys" do
      Report.create!(:key => 'users_by_organization')
      Report.new.should validate_uniqueness_of( :key )
    end

    it "should accept only keys for certain Reports" do
      r = Report.new(:key => 'users_by_organization')
      r.should be_valid
      r = Report.new(:key => 'blahblah')
      r.should_not be_valid
    end

    it "should save attachments" do
      report      = Report.new(:key => 'users_by_organization')
      report.should_receive(:save_attached_files).twice.and_return(true)
      report.save.should == true
    end
  end
end


# == Schema Information
#
# Table name: reports
#
#  id                         :integer         primary key
#  key                        :string(255)
#  created_at                 :timestamp
#  updated_at                 :timestamp
#  csv_file_name              :string(255)
#  csv_content_type           :string(255)
#  csv_file_size              :integer
#  csv_updated_at             :timestamp
#  formatted_csv_file_name    :string(255)
#  formatted_csv_content_type :string(255)
#  formatted_csv_file_size    :integer
#  formatted_csv_updated_at   :timestamp
#

