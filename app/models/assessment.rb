class Assessment < ApplicationRecord
  KINDS = %w[ quiz exam project assignment presentation essay lab ].freeze
  KIND_LABELS = {
    "quiz" => "测验",
    "exam" => "考试",
    "project" => "项目",
    "assignment" => "作业",
    "presentation" => "展示",
    "essay" => "论文",
    "lab" => "实验"
  }.freeze
  PASS_MARK = 50

  belongs_to :course
  has_many :submissions, dependent: :destroy

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :min_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :min_score_needs_hurdle

  def submission_for(user)
    return nil if user.nil?

    if group_work?
      group = course.group_for(user)
      group ? submissions.find_by(group_id: group.id) : nil
    else
      submissions.find_by(user_id: user.id)
    end
  end

  def grade_for(user)
    submission_for(user)&.grade
  end

  def adjusted_score_for(user)
    grade = grade_for(user)
    return nil if grade.nil?

    (grade.score.to_f * adjustment_factor_for(user)).clamp(0, 100)
  end

  def weighted_score_for(user)
    score = adjusted_score_for(user)
    return 0 if score.nil?

    score * weight.to_f / 100
  end

  def hurdle_failed?(user)
    return false unless hurdle?
    return true if submission_for(user).nil?
    return false if min_score.nil?

    adjusted_score_for(user).to_f < min_score.to_f
  end

  def outcome_for(user)
    return nil unless pass_fail?

    score = adjusted_score_for(user)
    return nil if score.nil?

    score >= PASS_MARK ? "通过" : "未通过"
  end

  def adjustment_factor_for(user)
    return 1 unless group_work?

    group = course.group_for(user)
    membership = group&.group_memberships&.find_by(user_id: user.id)
    membership ? membership.adjustment_factor.to_f : 1
  end

  private

  def min_score_needs_hurdle
    errors.add(:min_score, "需要同时勾选门槛") if min_score.present? && !hurdle?
  end
end
