class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.string :title, null: false
      t.string :body, null: false
      t.references :user, null: false, foreign_key: {on_delete: :cascade}
      t.boolean :public, default: true

      t.timestamps
    end
  end
end
