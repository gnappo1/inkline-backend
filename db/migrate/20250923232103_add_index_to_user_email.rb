class AddIndexToUserEmail < ActiveRecord::Migration[8.0]
  def change
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
  end
end
