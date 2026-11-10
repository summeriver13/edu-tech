class Course < ApplicationRecord
  has_many :resources, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :assessments, dependent: :destroy
  has_many :course_memberships, dependent: :destroy
  has_many :members, through: :course_memberships, source: :user
  has_many :groups, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :attempts, dependent: :destroy
  has_many :contributions, dependent: :destroy

  mount_uploader :cover, CoverUploader

  validates :title, :description, :course_number, presence: true
  validates :course_number, uniqueness: true
  validates :credit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :term_weeks, numericality: { greater_than: 0, only_integer: true }
  validates :time_zone, presence: true
  validate :time_zone_is_valid

  scope :search, ->(query) {
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query)}%"
    where("title LIKE :pattern OR course_number LIKE :pattern OR description LIKE :pattern", pattern: pattern)
  }

  def zone
    Time.find_zone(time_zone) || Time.zone
  end

  def local_time(time)
    time&.in_time_zone(zone)
  end

  def week_of(time)
    return nil if time.nil? || week1_start.nil?

    days = (local_time(time).to_date - week1_start).to_i
    return nil if days.negative?

    (days / 7) + 1
  end

  def current_week
    week_of(Time.current)
  end

  def assessment_weight_total
    assessments.sum(:weight)
  end

  def member?(user)
    return false if user.nil?
    return true if user.admin?

    course_memberships.exists?(user_id: user.id)
  end

  def group_for(user)
    return nil if user.nil?

    groups.joins(:group_memberships).find_by(group_memberships: { user_id: user.id })
  end

  def grade_for(user)
    assessments.sum { |assessment| assessment.weighted_score_for(user) }.round(1)
  end

  def time_zone_is_valid
    errors.add(:time_zone, "不是有效时区") if Time.find_zone(time_zone).nil?
  end

  def manageable_by?(user)
    return false if user.nil?
    return true if user.admin?

    course_memberships.where(user_id: user.id, role: CourseMembership::MANAGE_ROLES).exists?
  end
end
