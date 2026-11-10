class Course < ApplicationRecord
  has_many :resources, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :assessments, dependent: :destroy
  has_many :course_memberships, dependent: :destroy
  has_many :members, through: :course_memberships, source: :user

  mount_uploader :cover, CoverUploader

  validates :title, :description, :course_number, presence: true
  validates :course_number, uniqueness: true
  validates :credit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :search, ->(query) {
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query)}%"
    where("title LIKE :pattern OR course_number LIKE :pattern OR description LIKE :pattern", pattern: pattern)
  }

  def assessment_weight_total
    assessments.sum(:weight)
  end

  def manageable_by?(user)
    return false if user.nil?
    return true if user.admin?

    course_memberships.where(user_id: user.id, role: CourseMembership::MANAGE_ROLES).exists?
  end
end
