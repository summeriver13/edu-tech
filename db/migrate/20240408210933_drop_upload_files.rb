class DropUploadFiles < ActiveRecord::Migration[7.1]
  def change
    drop_table :upload_files
  end
end
