class ModelHelp < ActiveRecord::Base

  ### Associations
  has_many :field_help
  has_many :comments, :as => :commentable, :dependent => :destroy

  # for active scaffold labels & drop downs
  def name
    model_name
  end
end




# == Schema Information
#
# Table name: model_helps
#
#  id             :integer         not null, primary key
#  model_name     :string(255)
#  short          :string(255)
#  long           :text
#  created_at     :datetime
#  updated_at     :datetime
#  comments_count :integer         default(0)
#

