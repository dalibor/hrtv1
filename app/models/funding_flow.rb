require 'lib/BudgetSpendHelpers'
class FundingFlow < ActiveRecord::Base
  include BudgetSpendHelpers

  ### Attributes
  attr_accessible :organization_text, :project_id, :data_response_id, :from, :to,
                  :self_provider_flag, :organization_id_from, :organization_id_to,
                  :spend, :budget

  ### Associations
  belongs_to :from, :class_name => "Organization", :foreign_key => "organization_id_from"
  belongs_to :to, :class_name => "Organization", :foreign_key => "organization_id_to"
  belongs_to :project
  belongs_to :project_from # funder's project
  belongs_to :data_response # TODO: deprecate in favour of: delegate :data_response, :to => :project

  alias :response :data_response
  alias :response= :data_response=

  ### Validations
  # validates_presence_of :project # ???
  validates_presence_of :data_response_id
  validates_presence_of :organization_id_from,
    :message => :"organization_id_from.missing"
  validates_presence_of :organization_id_to,
    :message => :"organization_id_to.missing"

  # if project from id == nil => then the user hasnt linked them
  # if project from id == 0 => then the user can't find Funder project in a list
  # if project from id > 0 => user has selected a Funder project
  validates_numericality_of :project_from_id, :greater_than_or_equal_to => 0, :unless => lambda {|fs| fs["project_from_id"].blank?}
  # if we pass "-1" then the user somehow selected "Add an Organization..."
  validates_numericality_of :organization_id_from, :greater_than_or_equal_to => 0,
    :unless => lambda {|fs| fs["project_from_id"].blank?},
    :message => :"organization_id_from.id_below_zero"

  ### Named scopes
  named_scope :ordered_by_id, { :order => 'id ASC' }

  delegate :organization, :to => :project

  def currency
    project.try(:currency)
  end

  def name
    "From: #{from.name} - To: #{to.name}"
  end

  def self.create_flows(params)
    unless params[:funding_flows].blank?
      params[:funding_flows].each_pair do |flow_id, project_id|
        ff = self.find(flow_id)
        ff.project_from_id = project_id
        ff.save
      end
    end
  end

  def self.bulk_update(response, funders)
    funders.each_pair do |funder_id, attributes|
      funder = response.funding_flows.find(funder_id)
      funder.attributes = attributes
      funder.save
    end
  end

  def funding_chains
    if self_funded?
      [FundingChain.new(
  { :organization_chain => [from, to],
        :budget => budget, :spend => spend})]
    else
      chains = from.best_guess_funding_chains_to(to, response.data_request) unless from.nil?

      unless chains.nil? or chains.empty?
        # TODO for better heurestics will need to pass
        # amounts up into best_guess_funding_chains_to
        FundingChain.adjust_amount_totals!(chains,
      spend.try(:>, 0) ?  spend : 0,
          budget.try(:>, 0) ? budget : 0)

        chains
      else
        error = from.nil? ? "From was nil" : "From guessed no chains"
        puts error
  #raise error
        [FundingChain.new(
          {:organization_chain => [Organization.new(:name => "Unspecified"), to],
           :budget => budget, :spend => spend})]
      end

    end
  end

  def self_funded?
    from == to
  end

  def donor_funded?
    ["Donor",  "Multilateral", "Bilateral"].include?(from.raw_type)
  end
end

# == Schema Information
#
# Table name: funding_flows
#
#  id                   :integer         not null, primary key
#  organization_id_from :integer
#  organization_id_to   :integer
#  project_id           :integer         indexed
#  created_at           :datetime
#  updated_at           :datetime
#  budget               :integer(10)
#  spend_q1             :integer(10)
#  spend_q2             :integer(10)
#  spend_q3             :integer(10)
#  spend_q4             :integer(10)
#  organization_text    :text
#  self_provider_flag   :integer         default(0), indexed
#  spend                :integer(10)
#  spend_q4_prev        :integer(10)
#  data_response_id     :integer         indexed
#  budget_q1            :integer(10)
#  budget_q2            :integer(10)
#  budget_q3            :integer(10)
#  budget_q4            :integer(10)
#  budget_q4_prev       :integer(10)
#  comments_count       :integer         default(0)
#  project_from_id      :integer
#

