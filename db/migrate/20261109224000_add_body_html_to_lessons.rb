class AddBodyHtmlToLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :body_html, :text
  end
end
