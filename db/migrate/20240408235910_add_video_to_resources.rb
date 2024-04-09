class AddVideoToResources < ActiveRecord::Migration[7.1]
  def change
    add_column :resources, :video, :string
  end
end
