# == Schema Information
#
# Table name: activities
#
#  id                     :integer         not null, primary key
#  name                   :string(255)
#  beneficiary            :string(255)
#  target                 :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  provider_id            :integer
#  other_cost_type_id     :integer
#  description            :text
#  type                   :string(255)
#  budget                 :decimal(, )
#  spend_q1               :decimal(, )
#  spend_q2               :decimal(, )
#  spend_q3               :decimal(, )
#  spend_q4               :decimal(, )
#  start                  :date
#  end                    :date
#  spend                  :decimal(, )
#  text_for_provider      :text
#  text_for_targets       :text
#  text_for_beneficiaries :text
#  spend_q4_prev          :decimal(, )
#  data_response_id       :integer
#  activity_id            :integer
#  budget_percentage      :decimal(, )
#  spend_percentage       :decimal(, )
#

require 'lib/ActAsDataElement'

class Activity < ActiveRecord::Base
  VALID_ROOT_TYPES = %w[Mtef Nha Nasa Nsp]

  acts_as_commentable
  include ActAsDataElement
  configure_act_as_data_element

  # Attributes
  attr_accessible :projects, :locations, :text_for_provider,
                  :provider, :name, :description,  :start, :end,
                  :text_for_beneficiaries, :beneficiaries,
                  :text_for_targets, :spend, :spend_q4_prev,
                  :spend_q1, :spend_q2, :spend_q3, :spend_q4,
                  :budget, :approved

  # Associations
  has_and_belongs_to_many :projects
  has_and_belongs_to_many :indicators
  has_and_belongs_to_many :locations
  belongs_to :provider, :foreign_key => :provider_id, :class_name => "Organization"
  has_and_belongs_to_many :organizations # organizations targeted by this activity / aided
  has_and_belongs_to_many :beneficiaries # codes representing who benefits from this activity
  has_many :sub_activities, :class_name => "SubActivity", :foreign_key => :activity_id
  has_many :code_assignments

  # Validations
  validate :approved_activity_cannot_be_changed

  # Callbacks
  before_update :update_all_classified_amount_caches

  # Named scopes
  named_scope :roots,     {:conditions => "activities.type IS NULL" }
  named_scope :with_type, lambda { |type| {:conditions => ["activities.type = ?", type]} }

  # delegate :providers, :to => :projects
  def valid_providers
    #TODO use delegates_to
    projects.valid_providers
  end

  def organization
    self.data_response.responding_organization
  end

  def organization_name
    organization.name
  end

  def districts
    self.projects.collect do |proj|
      proj.locations
    end.flatten.uniq
  end

  def classified
    #TODO override in othercosts and subactivities
    budget? && budget_by_district? && budget_by_cost_category? && spend? && spend_by_district? && spend_by_cost_category?
  end

  # TODO: use the cached values to check if the activity is classified!
  def budget?
    CodingBudget.classified(self)
  end

  def budget_by_district?
    CodingBudgetDistrict.classified(self)
  end

  def budget_by_cost_category?
    CodingBudgetCostCategorization.classified(self)
  end

  def spend?
    CodingSpend.classified(self)
  end

  def spend_by_district?
    CodingSpendDistrict.classified(self)
  end

  def spend_by_cost_category?
    CodingSpendCostCategorization.classified(self)
  end

  # Called from migration 20100924042908_add_cache_columns_for_classified_to_activity.rb
  def update_classified_amount_cache(type)
    set_classified_amount_cache(type)
    self.save
  end

  # Updates classified amount caches if budget or spend have been changed
  def update_all_classified_amount_caches
    if budget_changed?
      [CodingBudget, CodingBudgetDistrict, CodingBudgetCostCategorization].each do |type|
        set_classified_amount_cache(type)
      end
    end
    if spend_changed?
      [CodingSpend, CodingSpendDistrict, CodingSpendCostCategorization].each do |type|
        set_classified_amount_cache(type)
      end
    end
  end

  private
  def approved_activity_cannot_be_changed
    errors.add(:approved, "approved activity cannot be changed") if changed? and approved and changed != ["approved"]
  end

  def max_codings(type)
    case type.to_s
    when "CodingBudget", "CodingBudgetDistrict", "CodingBudgetCostCategorization"
      max = budget
    when "CodingSpend", "CodingSpendDistrict", "CodingSpendCostCategorization"
      max = spend
    end
  end

  def set_classified_amount_cache(type)
    amount = type.codings_sum(type.available_codes(self), self, max_codings(type))
    self.send("#{type}_amount=",  amount)
  end
end
