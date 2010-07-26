
class Organization < ActiveRecord::Base
  attr_accessible :name

  acts_as_commentable

  has_many :users # people in this organization

  has_many :data_requests_made, :class_name => "DataRequest",
    :foreign_key => :organization_id_requester

  has_many :data_responses, :foreign_key => :organization_id_responder

  has_many :out_flows, :class_name => "FundingFlow", :foreign_key => "organization_id_from"
  has_many :in_flows, :class_name => "FundingFlow", :foreign_key => "organization_id_to"

  has_many :donor_for, :through => :out_flows, :source => :project
  has_many :implementor_for, :through => :in_flows, :source => :project
  has_many :provider_for, :class_name => "Activity", :foreign_key => :provider_id

  #has_many :funding_flows #TODO should be named like owned_funding_flows
  # for some reason the association above was giving AS problems... when i trie dto implement the subforms

  has_and_belongs_to_many :locations

  def to_s
    name
  end

  def self.providers_for locations
    orgs=Organization.find_by_sql( ["
      SELECT o.id
      FROM organizations o, locations_organizations l
      WHERE o.id=l.organization_id
      AND l.location_id in (?)",
      locations.collect {|l| l.id} ])
  end
end
