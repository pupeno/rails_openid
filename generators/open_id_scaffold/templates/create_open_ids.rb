class CreateOpenIds < ActiveRecord::Migration
  def self.up
    create_table :open_ids do |t|
      # TODO: Change if your users table is not users.
      t.integer :user_id
      t.string :identifier
      t.string :display_identifier

      t.timestamps
    end
  end

  def self.down
    drop_table :open_ids
  end
end
