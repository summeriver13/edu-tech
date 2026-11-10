class RenameAssignmentsToAssessments < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :submissions, :assignments
    remove_index :submissions, column: %i[ assignment_id user_id ]

    rename_column :submissions, :assignment_id, :assessment_id
    add_index :submissions, %i[ assessment_id user_id ], unique: true

    rename_table :assignments, :assessments

    change_table :assessments, bulk: true do |t|
      t.string :key
      t.string :kind, null: false, default: "assignment"
      t.decimal :weight, null: false, default: 0
      t.boolean :group_work, null: false, default: false
      t.json :slos, null: false, default: []
      t.string :scope
      t.string :venue
      t.datetime :opens_at
    end

    add_index :assessments, %i[ course_id key ], unique: true
    add_foreign_key :submissions, :assessments, column: :assessment_id
  end
end
