class Question < ApplicationRecord
  KINDS = %w[ single boolean short ].freeze

  belongs_to :course
  belongs_to :lesson, optional: true
  has_many :answers, dependent: :destroy

  validates :stem, presence: true
  validates :answer, presence: true
  validates :kind, inclusion: { in: KINDS }
  validate :lesson_belongs_to_course

  def correct?(response)
    given = normalize(response)
    return false if given.empty?

    given == normalize(answer)
  end

  private

  def lesson_belongs_to_course
    return if lesson.nil? || lesson.course_id == course_id

    errors.add(:lesson, "必须属于同一课程")
  end

  def normalize(value)
    value.to_s.strip.downcase
  end
end
