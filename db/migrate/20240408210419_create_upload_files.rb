class CreateUploadFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :upload_files do |t|
      t.string :name

      t.timestamps
    end
  end
end
