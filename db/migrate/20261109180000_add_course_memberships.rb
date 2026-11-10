class AddCourseMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :course_memberships do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "student"
      t.timestamps
    end

    add_index :course_memberships, %i[ course_id user_id ], unique: true
    add_column :courses, :repo_url, :string
    add_column :courses, :commit_sha, :string
    add_column :courses, :synced_at, :datetime
  end
end
