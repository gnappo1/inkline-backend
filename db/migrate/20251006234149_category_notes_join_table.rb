class CategoryNotesJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_join_table :categories, :notes do |t|
      t.index [:category_id, :note_id]
      t.index [:note_id, :category_id]
      # enforce uniqueness
      t.index [:category_id, :note_id], unique: true, name: "index_categories_notes_unique"
    end

    add_foreign_key :categories_notes, :categories, on_delete: :cascade
    add_foreign_key :categories_notes, :notes, on_delete: :cascade
  end
end