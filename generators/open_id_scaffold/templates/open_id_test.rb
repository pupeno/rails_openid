require 'test_helper'

class OpenIdTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: open_ids
#
#  id                 :integer(4)      not null, primary key
#  user_id            :integer(4)      not null
#  identifier         :string(255)     not null
#  display_identifier :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#

