class AlterNoteBodyToText < ActiveRecord::Migration[8.0]
  def change
    change_column :notes, :body, :text, null: false
  end
end
