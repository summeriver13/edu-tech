class FixCourseAssociations < ActiveRecord::Migration[8.1]
  def up
    rebuild_activities
    rebuild_resources
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def rebuild_activities
    create_table :activities_new, force: true do |t|
      t.references :course, null: false, foreign_key: true, index: false
      t.string :activity_type
      t.datetime :start_time
      t.datetime :end_time
      t.string :location
      t.text :description
      t.timestamps
    end
    execute <<~SQL
      INSERT INTO activities_new (id, course_id, activity_type, start_time, end_time, location, description, created_at, updated_at)
      SELECT id, CAST(course_id AS INTEGER), activity_type, start_time, end_time, location, description, created_at, updated_at
      FROM activities
      WHERE CAST(course_id AS INTEGER) IN (SELECT id FROM courses)
    SQL
    drop_table :activities
    rename_table :activities_new, :activities
    add_index :activities, :course_id
  end

  def rebuild_resources
    create_table :resources_new, force: true do |t|
      t.references :course, null: false, foreign_key: true, index: false
      t.string :resource_type
      t.string :name
      t.string :url
      t.string :video
      t.text :description
      t.timestamps
    end
    execute <<~SQL
      INSERT INTO resources_new (id, course_id, resource_type, name, url, video, description, created_at, updated_at)
      SELECT id, CAST(course_id AS INTEGER), resource_type, name, url, video, description, created_at, updated_at
      FROM resources
      WHERE CAST(course_id AS INTEGER) IN (SELECT id FROM courses)
    SQL
    drop_table :resources
    rename_table :resources_new, :resources
    add_index :resources, :course_id
  end
end
