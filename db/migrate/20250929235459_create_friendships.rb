class CreateFriendships < ActiveRecord::Migration[8.0]
  def change
    create_table :friendships do |t|
      t.references :sender, null: false, foreign_key: {to_table: :users, on_delete: :cascade}
      t.references :receiver, null: false, foreign_key: {to_table: :users, on_delete: :cascade}
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    # No self friendship
    add_check_constraint :friendships, "sender_id <> receiver_id", name: "chk_friendship_not_self"

    # Unordered uniqueness: prevents both duplicates and reverse duplicates
    if ActiveRecord::Base.connection.adapter_name =~ /sqlite/i
      add_index :friendships,
        "CASE WHEN sender_id < receiver_id THEN sender_id ELSE receiver_id END, " \
        "CASE WHEN sender_id < receiver_id THEN receiver_id ELSE sender_id END",
        unique: true,
        name: "idx_friendships_unique_pair"
    else
      add_index :friendships,
        "LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id)",
        unique: true,
        name: "idx_friendships_unique_pair"
    end

    add_index :friendships, [:sender_id, :status]
    add_index :friendships, [:receiver_id, :status]

  end
end
