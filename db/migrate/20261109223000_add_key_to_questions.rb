class AddKeyToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :key, :string
    add_index :questions, %i[ course_id key ], unique: true, where: "key IS NOT NULL"
  end
end
