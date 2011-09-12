require 'validators'
class DataRequest < ActiveRecord::Base
  ### Attributes
  attr_accessible :organization_id, :title, :final_review,
                  :start_date, :end_date, :due_date, :budget, :spend,
                  :purposes, :locations, :inputs, :budget_by_quarter

  ### Associations
  belongs_to :organization
  has_many :data_responses, :dependent => :destroy

  ### Validations
  validates_presence_of :organization_id, :title
  validates_date :due_date
  validates_date :start_date
  validates_date :end_date
  validates_dates_order :start_date, :end_date, :message => "Start date must come before End date."

  ### Callbacks
  after_create :create_data_responses

  ### Named scopes
  named_scope :sorted, { :order => "data_requests.start_date" }

  ### Instance Methods

  def name
    title
  end

  def status
    return 'Final review' if final_review?
    return 'In progress'
  end

  private
    def create_data_responses
      Organization.reporting.all.each do |organization|
        dr = organization.data_responses.find(:first,
          :conditions => {:data_request_id => self.id})
        unless dr
          dr = organization.data_responses.new
          dr.data_request = self
          dr.save!
        end
      end
    end
end









# == Schema Information
#
# Table name: data_requests
#
#  id                :integer         not null, primary key
#  organization_id   :integer
#  title             :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  due_date          :date
#  start_date        :date
#  end_date          :date
#  final_review      :boolean         default(FALSE)
#  purposes          :boolean         default(TRUE)
#  locations         :boolean         default(TRUE)
#  inputs            :boolean         default(TRUE)
#  budget_by_quarter :boolean         default(FALSE)
#

