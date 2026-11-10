class Course < ApplicationRecord
  has_many :resources, dependent: :destroy
  has_many :activities, dependent: :destroy

  mount_uploader :cover, CoverUploader

  validates :title, :description, :course_number, presence: true
  validates :course_number, uniqueness: true
  validates :credit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :search, ->(query) {
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query)}%"
    where("title LIKE :pattern OR course_number LIKE :pattern OR description LIKE :pattern", pattern: pattern)
  }
end
