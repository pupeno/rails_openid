class OpenId < ActiveRecord::Base
  # TODO: If your user model is not user, change it here.
  # TODO: Add has_many :open_ids to your user model.
  belongs_to :user

  # TODO: If your user model is not user, change it here.
  validates_presence_of :user
  validates_presence_of :identifier
  attr_accessible :identifier, :display_identifier
end

# == Schema Information
#
# Table name: open_ids
#
#  id                 :integer         not null, primary key
#  user_id            :integer
#  identifier         :string(255)
#  display_identifier :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#
