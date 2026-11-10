class AddLessonsAndEnrollment < ActiveRecord::Migration[8.1]
  def change
    add_column :courses, :self_enrollment, :boolean, null: false, default: false

    create_table :lessons do |t|
      t.references :course, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string :title, null: false
      t.string :source_path
      t.text :body
      t.timestamps
    end
    add_index :lessons, %i[ course_id position ]
    add_index :lessons, %i[ course_id source_path ], unique: true, where: "source_path IS NOT NULL"

    create_table :lesson_completions do |t|
      t.references :lesson, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :completed_at, null: false
      t.timestamps
    end
    add_index :lesson_completions, %i[ lesson_id user_id ], unique: true
  end
end
