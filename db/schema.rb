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

  create_table "kenguru_answers", force: :cascade do |t|
    t.bigint "kenguru_question_id", null: false
    t.text "text", null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kenguru_question_id", "correct"], name: "index_kenguru_answers_on_kenguru_question_id_and_correct", unique: true, where: "(correct = true)"
    t.index ["kenguru_question_id"], name: "index_kenguru_answers_on_kenguru_question_id"
  end

  create_table "kenguru_questions", force: :cascade do |t|
    t.text "text", null: false
    t.integer "year", null: false
    t.integer "grade", null: false
    t.integer "index", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["year", "grade", "index"], name: "index_kenguru_questions_on_year_and_grade_and_index", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.string "questionable_type", null: false
    t.integer "questionable_id", null: false
    t.integer "minimum_age", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["questionable_type", "questionable_id"], name: "index_questions_on_questionable_type_and_questionable_id"
  end

  add_foreign_key "kenguru_answers", "kenguru_questions"
end
