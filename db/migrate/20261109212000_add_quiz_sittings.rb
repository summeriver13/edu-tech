class AddQuizSittings < ActiveRecord::Migration[8.1]
  def change
    add_column :assessments, :sittings, :integer
    add_column :assessments, :best_of, :integer
    add_reference :attempts, :assessment, foreign_key: true
  end
end
