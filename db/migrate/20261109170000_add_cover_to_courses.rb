class AddCoverToCourses < ActiveRecord::Migration[8.1]
  def change
    add_column :courses, :cover, :string
    remove_column :courses, :image_url, :string
  end
end
