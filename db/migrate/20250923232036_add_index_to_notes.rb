class AddIndexToNotes < ActiveRecord::Migration[8.0]
  def change
    add_index :notes, [:user_id, :created_at], name: "index_notes_on_user_id_created_at"
    add_index :notes, [:created_at, :id], name: "index_notes_on_created_at_id"
  end
end
