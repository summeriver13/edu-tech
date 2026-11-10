class AddSyncStateToCourses < ActiveRecord::Migration[8.1]
  def change
    add_column :courses, :syncing_at, :datetime
    add_column :courses, :sync_error, :string
  end
end
