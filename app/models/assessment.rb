class Assessment < ApplicationRecord
  KINDS = %w[ quiz exam project assignment ].freeze
  KIND_LABELS = {
    "quiz" => "测验",
    "exam" => "考试",
    "project" => "项目",
    "assignment" => "作业"
  }.freeze

  belongs_to :course
  has_many :submissions, dependent: :destroy

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  def submission_for(user)
    return nil if user.nil?

    if group_work?
      group = course.group_for(user)
      group ? submissions.find_by(group_id: group.id) : nil
    else
      submissions.find_by(user_id: user.id)
    end
  end

  def weighted_score_for(user)
    grade = submission_for(user)&.grade
    return 0 if grade.nil?

    score = (grade.score.to_f * adjustment_factor_for(user)).clamp(0, 100)
    score * weight.to_f / 100
  end

  def adjustment_factor_for(user)
    return 1 unless group_work?

    group = course.group_for(user)
    membership = group&.group_memberships&.find_by(user_id: user.id)
    membership ? membership.adjustment_factor.to_f : 1
  end
end
