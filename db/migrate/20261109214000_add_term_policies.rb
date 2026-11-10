class AddTermPolicies < ActiveRecord::Migration[8.1]
  def change
    add_column :courses, :census_at, :date
    add_column :courses, :min_attendance, :integer
    add_column :assessments, :ai_policy, :string
  end
end
