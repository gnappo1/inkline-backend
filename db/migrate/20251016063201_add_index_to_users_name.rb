class AddIndexToUsersName < ActiveRecord::Migration[8.0]
  def change
    add_index :users, "LOWER(first_name)", name: "index_users_on_lower_first_name"
    add_index :users, "LOWER(last_name)",  name: "index_users_on_lower_last_name"
  end
end
