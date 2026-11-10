class AddDeliverablesAndRules < ActiveRecord::Migration[8.1]
  def change
    create_table :deliverables do |t|
      t.references :assessment, null: false, foreign_key: true
      t.string :name, null: false
      t.datetime :due_at
      t.timestamps
    end
    add_index :deliverables, %i[ assessment_id name ], unique: true

    remove_index :submissions, %i[ assessment_id user_id ]
    add_reference :submissions, :deliverable, foreign_key: true
    add_index :submissions, %i[ assessment_id deliverable_id user_id ]

    add_column :assessments, :word_limit, :integer
    add_column :assessments, :word_limit_tolerance, :integer, null: false, default: 10
    add_column :assessments, :group_min, :integer
    add_column :assessments, :group_max, :integer

    add_column :courses, :late_penalty_percent, :decimal, null: false, default: 0
    add_column :courses, :late_penalty_max_days, :integer
  end
end
