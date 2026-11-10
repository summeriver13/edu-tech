class Attempt < ApplicationRecord
  belongs_to :course
  belongs_to :user
  belongs_to :assessment, optional: true
  belongs_to :lesson, optional: true
  has_many :answers, dependent: :destroy

  validates :taken_at, presence: true
  validates :score, :total, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :assessment_belongs_to_course
  validate :lesson_belongs_to_course

  def percent
    return 0 if total.zero?

    (score * 100.0 / total).round
  end

  private

  def lesson_belongs_to_course
    return if lesson.nil? || lesson.course_id == course_id

    errors.add(:lesson, "必须属于同一课程")
  end

  def assessment_belongs_to_course
    return if assessment.nil? || assessment.course_id == course_id

    errors.add(:assessment, "必须属于同一课程")
  end
end
