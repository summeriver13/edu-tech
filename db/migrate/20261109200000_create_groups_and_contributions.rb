class CreateGroupsAndContributions < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.references :course, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :groups, %i[ course_id name ], unique: true

    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "member"
      t.string :module_name
      t.decimal :adjustment_factor, precision: 4, scale: 2, null: false, default: 1.0
      t.timestamps
    end
    add_index :group_memberships, %i[ group_id user_id ], unique: true

    create_table :contributions do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :on_date, null: false
      t.string :task, null: false
      t.decimal :hours, precision: 5, scale: 1, null: false, default: 0
      t.string :evidence_url
      t.string :status, null: false, default: "done"
      t.timestamps
    end

    create_table :grades do |t|
      t.references :submission, null: false, foreign_key: true, index: { unique: true }
      t.decimal :score, precision: 5, scale: 2, null: false, default: 0
      t.text :feedback
      t.timestamps
    end

    add_reference :submissions, :group, foreign_key: true
  end
end
