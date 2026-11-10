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

ActiveRecord::Schema[8.1].define(version: 2026_11_09_212000) do
  create_table "activities", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "activity_type"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "location"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_activities_on_course_id"
  end

  create_table "answers", force: :cascade do |t|
    t.integer "attempt_id", null: false
    t.integer "question_id", null: false
    t.string "response"
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attempt_id"], name: "index_answers_on_attempt_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "assessments", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "title", null: false
    t.text "description"
    t.datetime "due_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "key"
    t.string "kind", default: "assignment", null: false
    t.decimal "weight", default: "0.0", null: false
    t.boolean "group_work", default: false, null: false
    t.json "slos", default: [], null: false
    t.string "scope"
    t.string "venue"
    t.datetime "opens_at"
    t.boolean "hurdle", default: false, null: false
    t.decimal "min_score"
    t.boolean "pass_fail", default: false, null: false
    t.integer "sittings"
    t.integer "best_of"
    t.index ["course_id", "key"], name: "index_assessments_on_course_id_and_key", unique: true
    t.index ["course_id"], name: "index_assessments_on_course_id"
  end

  create_table "attempts", force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "user_id", null: false
    t.integer "score", default: 0, null: false
    t.integer "total", default: 0, null: false
    t.datetime "taken_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assessment_id"
    t.index ["assessment_id"], name: "index_attempts_on_assessment_id"
    t.index ["course_id"], name: "index_attempts_on_course_id"
    t.index ["user_id"], name: "index_attempts_on_user_id"
  end

  create_table "contributions", force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "user_id", null: false
    t.date "on_date", null: false
    t.string "task", null: false
    t.decimal "hours", precision: 5, scale: 1, default: "0.0", null: false
    t.string "evidence_url"
    t.string "status", default: "done", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_contributions_on_course_id"
    t.index ["user_id"], name: "index_contributions_on_user_id"
  end

  create_table "course_memberships", force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "user_id", null: false
    t.string "role", default: "student", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "user_id"], name: "index_course_memberships_on_course_id_and_user_id", unique: true
    t.index ["course_id"], name: "index_course_memberships_on_course_id"
    t.index ["user_id"], name: "index_course_memberships_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.float "credit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "course_number"
    t.string "cover"
    t.string "repo_url"
    t.string "commit_sha"
    t.datetime "synced_at"
    t.string "time_zone", default: "Asia/Shanghai", null: false
    t.date "week1_start"
    t.integer "term_weeks", default: 18, null: false
    t.index ["course_number"], name: "index_courses_on_course_number", unique: true
  end

  create_table "grades", force: :cascade do |t|
    t.integer "submission_id", null: false
    t.decimal "score", precision: 5, scale: 2, default: "0.0", null: false
    t.text "feedback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id"], name: "index_grades_on_submission_id", unique: true
  end

  create_table "group_memberships", force: :cascade do |t|
    t.integer "group_id", null: false
    t.integer "user_id", null: false
    t.string "role", default: "member", null: false
    t.string "module_name"
    t.decimal "adjustment_factor", precision: 4, scale: 2, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_group_memberships_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "name"], name: "index_groups_on_course_id_and_name", unique: true
    t.index ["course_id"], name: "index_groups_on_course_id"
  end

  create_table "questions", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "topic"
    t.string "slo"
    t.string "kind", default: "single", null: false
    t.text "stem", null: false
    t.json "choices", default: [], null: false
    t.string "answer", null: false
    t.text "explanation"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_questions_on_course_id"
  end

  create_table "resources", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "resource_type"
    t.string "name"
    t.string "url"
    t.string "video"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_resources_on_course_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.integer "user_id", null: false
    t.text "body"
    t.string "file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "group_id"
    t.index ["assessment_id", "user_id"], name: "index_submissions_on_assessment_id_and_user_id", unique: true
    t.index ["assessment_id"], name: "index_submissions_on_assessment_id"
    t.index ["group_id"], name: "index_submissions_on_group_id"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "member", null: false
  end

  add_foreign_key "activities", "courses"
  add_foreign_key "answers", "attempts"
  add_foreign_key "answers", "questions"
  add_foreign_key "assessments", "courses"
  add_foreign_key "attempts", "assessments"
  add_foreign_key "attempts", "courses"
  add_foreign_key "attempts", "users"
  add_foreign_key "contributions", "courses"
  add_foreign_key "contributions", "users"
  add_foreign_key "course_memberships", "courses"
  add_foreign_key "course_memberships", "users"
  add_foreign_key "grades", "submissions"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "courses"
  add_foreign_key "questions", "courses"
  add_foreign_key "resources", "courses"
  add_foreign_key "submissions", "assessments"
  add_foreign_key "submissions", "groups"
  add_foreign_key "submissions", "users"
end
