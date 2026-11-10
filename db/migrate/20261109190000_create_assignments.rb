class CreateAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :assignments do |t|
      t.references :course, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.datetime :due_at
      t.timestamps
    end

    create_table :submissions do |t|
      t.references :assignment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body
      t.string :file
      t.timestamps
    end

    add_index :submissions, %i[ assignment_id user_id ], unique: true
  end
end
