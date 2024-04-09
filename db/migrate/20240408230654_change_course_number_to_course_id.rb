class ChangeCourseNumberToCourseId < ActiveRecord::Migration[7.1]
  def change
    rename_column :activities, :course_number, :course_id
    rename_column :resources, :course_number, :course_id
    # Assuming courses table already has 'id' column as primary key
    add_foreign_key :activities, :courses, column: :course_id
    add_foreign_key :resources, :courses, column: :course_id
  end
end
