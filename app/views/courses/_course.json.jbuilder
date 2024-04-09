json.extract! course, :id, :course_number, :title, :description, :image_url, :credit, :created_at, :updated_at
json.url course_url(course, format: :json)
