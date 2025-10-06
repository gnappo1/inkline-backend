# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_06_234149) do
  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "LOWER(name)", name: "index_categories_on_lower_name", unique: true
    t.index ["name"], name: "index_categories_on_name"
  end

  create_table "categories_notes", id: false, force: :cascade do |t|
    t.integer "category_id", null: false
    t.integer "note_id", null: false
    t.index ["category_id", "note_id"], name: "index_categories_notes_on_category_id_and_note_id"
    t.index ["category_id", "note_id"], name: "index_categories_notes_unique", unique: true
    t.index ["note_id", "category_id"], name: "index_categories_notes_on_note_id_and_category_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.integer "sender_id", null: false
    t.integer "receiver_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "CASE WHEN sender_id < receiver_id THEN sender_id ELSE receiver_id END, CASE WHEN sender_id < receiver_id THEN receiver_id ELSE sender_id END", name: "idx_friendships_unique_pair", unique: true
    t.index ["receiver_id", "status"], name: "index_friendships_on_receiver_id_and_status"
    t.index ["receiver_id"], name: "index_friendships_on_receiver_id"
    t.index ["sender_id", "status"], name: "index_friendships_on_sender_id_and_status"
    t.index ["sender_id"], name: "index_friendships_on_sender_id"
    t.check_constraint "sender_id <> receiver_id", name: "chk_friendship_not_self"
  end

  create_table "notes", force: :cascade do |t|
    t.string "title", null: false
    t.text "body", null: false
    t.integer "user_id", null: false
    t.boolean "public", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_notes_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "client"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower(email)", name: "index_users_on_lower_email", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "categories_notes", "categories", on_delete: :cascade
  add_foreign_key "categories_notes", "notes", on_delete: :cascade
  add_foreign_key "friendships", "users", column: "receiver_id", on_delete: :cascade
  add_foreign_key "friendships", "users", column: "sender_id", on_delete: :cascade
  add_foreign_key "notes", "users", on_delete: :cascade
end
