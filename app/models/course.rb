class Course < ApplicationRecord
  has_many :resources, dependent: :destroy
  has_many :activities, dependent: :destroy

  validates :title, :description, :course_number, presence: true
  validates :course_number, uniqueness: true
  validates :credit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
