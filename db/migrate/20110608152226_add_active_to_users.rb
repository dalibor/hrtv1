class AddActiveToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :active, :boolean, :default => false

    User.reset_column_information
    load 'db/fixes/add_active_to_present_users.rb'
  end

  def self.down
    remove_column :users, :active
  end
end