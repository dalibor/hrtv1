class Comment < ActiveRecord::Base

  acts_as_tree :order => 'created_at DESC'

  ### Attributes
  attr_accessible :comment, :parent_id

  ### Validations
  validates_presence_of :comment, :user_id, :commentable_id, :commentable_type

  ### Associations
  belongs_to :user
  belongs_to :commentable, :polymorphic => true

  ### Scopes
  default_scope :order => 'created_at ASC'

  ### Named scopes
  named_scope :on_all, lambda { |dr_ids|
    { :joins => "LEFT OUTER JOIN projects p ON p.id = comments.commentable_id
                 LEFT OUTER JOIN data_responses dr ON dr.id = comments.commentable_id
                 LEFT OUTER JOIN activities a ON a.id = comments.commentable_id
                 LEFT OUTER JOIN activities oc ON oc.id = comments.commentable_id ",
      :conditions => ["comments.created_at > :start_date
                        AND ((comments.commentable_type = 'DataResponse'
                          AND dr.id IN (:drs))
                        OR (comments.commentable_type = 'Project'
                          AND p.data_response_id IN (:drs))
                        OR (comments.commentable_type = 'Activity'
                          AND a.type IS NULL
                          AND a.data_response_id IN (:drs))
                        OR (comments.commentable_type = 'Activity'
                          AND oc.type = 'OtherCost'
                          AND oc.data_response_id IN (:drs)))",
                       {:drs => dr_ids, :start_date => DateTime.now - 6.months}],
     :order => "created_at DESC" }
  }

  named_scope :limit, lambda { |limit| {:limit => limit} }
end






# == Schema Information
#
# Table name: comments
#
#  id               :integer         not null, primary key
#  comment          :text            default("")
#  commentable_id   :integer         indexed
#  commentable_type :string(255)     indexed
#  user_id          :integer         indexed
#  created_at       :datetime
#  updated_at       :datetime
#  parent_id        :integer
#

