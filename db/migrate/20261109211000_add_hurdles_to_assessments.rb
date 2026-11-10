class AddHurdlesToAssessments < ActiveRecord::Migration[8.1]
  def change
    add_column :assessments, :hurdle, :boolean, null: false, default: false
    add_column :assessments, :min_score, :decimal
    add_column :assessments, :pass_fail, :boolean, null: false, default: false
  end
end
