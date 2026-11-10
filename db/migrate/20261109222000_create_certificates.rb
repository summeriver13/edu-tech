class CreateCertificates < ActiveRecord::Migration[8.1]
  def change
    create_table :certificates do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :serial, null: false
      t.datetime :issued_at, null: false
      t.timestamps
    end
    add_index :certificates, :serial, unique: true
    add_index :certificates, %i[ course_id user_id ], unique: true
  end
end
