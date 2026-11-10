class AddTermToCourses < ActiveRecord::Migration[8.1]
  def change
    add_column :courses, :time_zone, :string, null: false, default: "Asia/Shanghai"
    add_column :courses, :week1_start, :date
    add_column :courses, :term_weeks, :integer, null: false, default: 18
  end
end
