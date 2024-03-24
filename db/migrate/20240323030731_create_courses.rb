class CreateCourses < ActiveRecord::Migration[7.1]
  def change
    create_table :courses do |t|
      t.string :title
      t.text :description
      t.string :image_url
      t.float :credit, precision: 3, scale: 1

      t.timestamps
    end
  end
end
