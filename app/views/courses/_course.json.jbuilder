json.extract! course, :id, :course_number, :title, :description, :credit, :created_at, :updated_at
json.cover course.cover.url if course.cover.present?
json.url course_url(course, format: :json)
