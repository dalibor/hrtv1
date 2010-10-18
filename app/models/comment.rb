# == Schema Information
#
# Table name: comments
#
#  id               :integer         primary key
#  title            :string(50)      default("")
#  comment          :text            default("")
#  commentable_id   :integer
#  commentable_type :string(255)
#  user_id          :integer
#  created_at       :timestamp
#  updated_at       :timestamp
#

class Comment < ActiveRecord::Base
  include ActsAsCommentable::Comment

  belongs_to :commentable, :polymorphic => true

  default_scope :order => 'created_at ASC'

  ### named scopes
  named_scope :by_projects, :joins => "JOIN comments c ON c.commentable_id = projects.id "
  named_scope :on_projects_for, lambda { |organization|
      { :joins => "JOIN projects p ON p.id = comments.commentable_id ",
        :conditions => ["p.data_response_id IN (?)", organization.data_responses.map(&:id).join(',') ]
      }
    }
  named_scope :on_funding_sources_for, lambda { |organization|
      { :joins => "JOIN funding_flows f ON f.id = comments.commentable_id ",
        :conditions => ["f.organization_id_to = ? AND f.data_response_id IN (?)", organization.id, organization.data_responses.map(&:id).join(',') ]
      }
    }
  named_scope :on_implementers_for, lambda { |organization|
      { :joins => "JOIN funding_flows f ON f.id = comments.commentable_id ",
        :conditions => ["f.organization_id_from = ? AND f.data_response_id IN (?)", organization.id, organization.data_responses.map(&:id).join(',') ]
      }
    }
  # Note, this assumes STI - which may (and should be removed)
  named_scope :on_activities_for, lambda { |organization|
      { :joins => "JOIN activities a ON a.id = comments.commentable_id ",
        :conditions => ["a.type is null AND a.data_response_id IN (?)", organization.data_responses.map(&:id).join(',') ]
      }
    }
  # Note, this assumes STI - which may (and should be removed)
  named_scope :on_other_costs_for, lambda { |organization|
      { :joins => "JOIN activities a ON a.id = comments.commentable_id ",
        :conditions => ["a.type = 'OtherCost' AND a.data_response_id IN (?)", organization.data_responses.map(&:id).join(',') ]
      }
    }



  ### public methods
  def authorized_for_read?
    if current_user
      if current_user.role?(:admin)
        return true
      else
        if %w[ModelHelp FieldHelp].include? commentable_type
          return true
        else
          if commentable == nil
            return false
          else
          commentable.data_response == current_user.current_data_response
          end
        end
      end
    else
      false
    end
  end
  def authorized_for_update?
    authorized_for_read?
  end
  def authorized_for_delete?
    authorized_for_read?
  end

end
