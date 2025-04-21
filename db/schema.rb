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

ActiveRecord::Schema[8.0].define(version: 2025_04_03_090217) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assignment_questions", force: :cascade do |t|
    t.bigint "assignment_id", null: false
    t.bigint "question_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id", "question_id"], name: "index_assignment_questions_on_assignment_id_and_question_id", unique: true
    t.index ["assignment_id"], name: "index_assignment_questions_on_assignment_id"
    t.index ["question_id"], name: "index_assignment_questions_on_question_id"
  end

  create_table "assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "question_count", null: false
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "possible_answers", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.text "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_possible_answers_on_question_id"
  end

  create_table "question_attachments", force: :cascade do |t|
    t.string "attachable_type", null: false
    t.integer "attachable_id", null: false
    t.jsonb "attachable_parameters", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "question_attachment_id"
    t.text "text", null: false
    t.text "answer", null: false
    t.text "explanation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_attachment_id"], name: "index_questions_on_question_attachment_id"
  end

  create_table "script_attachments", force: :cascade do |t|
    t.text "code", null: false
  end

  create_table "user_answers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "assignment_question_id", null: false
    t.text "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_question_id"], name: "index_user_answers_on_assignment_question_id"
    t.index ["user_id"], name: "index_user_answers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "assignment_questions", "assignments"
  add_foreign_key "assignment_questions", "questions"
  add_foreign_key "assignments", "users"
  add_foreign_key "possible_answers", "questions"
  add_foreign_key "user_answers", "assignment_questions"
  add_foreign_key "user_answers", "users"
end
