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
  has_many :attempts, dependent: :nullify

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :min_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :sittings, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :best_of, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validate :min_score_needs_hurdle
  validate :best_of_fits_sittings

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

  def raw_score_for(user)
    grade = grade_for(user)
    return grade.score.to_f unless grade.nil?

    attempt_score_for(user)
  end

  def adjusted_score_for(user)
    raw = raw_score_for(user)
    return nil if raw.nil?

    (raw * adjustment_factor_for(user)).clamp(0, 100)
  end

  def attempt_score_for(user)
    return nil if user.nil?

    percents = attempts.where(user_id: user.id).map(&:percent).sort.reverse
    return nil if percents.empty?

    taken = best_of.present? ? percents.first(best_of) : percents
    (taken.sum.to_f / taken.size).round(1)
  end

  def weighted_score_for(user)
    score = adjusted_score_for(user)
    return 0 if score.nil?

    score * weight.to_f / 100
  end

  def hurdle_failed?(user)
    return false unless hurdle?

    if min_score.nil?
      submission_for(user).nil? && attempt_score_for(user).nil?
    else
      adjusted_score_for(user).nil? || adjusted_score_for(user) < min_score.to_f
    end
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

  def best_of_fits_sittings
    return if best_of.nil? || sittings.nil?
    return if best_of <= sittings

    errors.add(:best_of, "不能超过次数")
  end
end
