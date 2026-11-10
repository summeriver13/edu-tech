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
  AI_POLICIES = %w[ not_permitted allowed_with_declaration ].freeze
  AI_POLICY_LABELS = {
    "not_permitted" => "禁止使用生成式 AI",
    "allowed_with_declaration" => "允许使用生成式 AI，需声明"
  }.freeze

  belongs_to :course
  has_many :submissions, dependent: :destroy
  has_many :attempts, dependent: :nullify
  has_many :deliverables, -> { order(:due_at, :id) }, dependent: :destroy, inverse_of: :assessment

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :min_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :sittings, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :best_of, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :word_limit, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :word_limit_tolerance, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :group_min, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :group_max, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :ai_policy, inclusion: { in: AI_POLICIES }, allow_nil: true
  validate :min_score_needs_hurdle
  validate :best_of_fits_sittings

  def submission_for(user, context = nil)
    return nil if user.nil?
    return context.submission(self, user) if context

    if group_work?
      group = course.group_for(user)
      group ? submissions.find_by(group_id: group.id) : nil
    else
      submissions.find_by(user_id: user.id)
    end
  end

  def grade_for(user, context = nil)
    submission_for(user, context)&.grade
  end

  def raw_score_for(user, context = nil)
    grade = grade_for(user, context)
    return grade.score.to_f unless grade.nil?

    attempt_score_for(user, context)
  end

  def adjusted_score_for(user, context = nil)
    raw = raw_score_for(user, context)
    return nil if raw.nil?

    (raw * adjustment_factor_for(user, context)).clamp(0, 100)
  end

  def attempt_score_for(user, context = nil)
    return nil if user.nil?

    percents = context ? context.attempt_percents(self, user) : attempts.where(user_id: user.id).map(&:percent)
    percents = percents.sort.reverse
    return nil if percents.empty?

    taken = best_of.present? ? percents.first(best_of) : percents
    (taken.sum.to_f / taken.size).round(1)
  end

  def penalized_score_for(user, context = nil)
    score = adjusted_score_for(user, context)
    return nil if score.nil?

    (score - late_penalty_for(submission_for(user, context))).clamp(0, 100)
  end

  def weighted_score_for(user, context = nil)
    score = penalized_score_for(user, context)
    return 0 if score.nil?

    score * weight.to_f / 100
  end

  def late_penalty_for(submission)
    return 0 if submission.nil?

    days = submission.late_days
    return 0 if days.zero?

    max_days = course.late_penalty_max_days
    return 100 if max_days.present? && days > max_days

    (days * course.late_penalty_percent.to_f).clamp(0, 100)
  end

  def word_range
    return nil if word_limit.nil?

    tolerance = word_limit_tolerance.to_i
    [ (word_limit * (100 - tolerance) / 100.0).round, (word_limit * (100 + tolerance) / 100.0).round ]
  end

  def hurdle_failed?(user, context = nil)
    return false unless hurdle?

    if min_score.nil?
      submission_for(user, context).nil? && attempt_score_for(user, context).nil?
    else
      adjusted_score_for(user, context).nil? || adjusted_score_for(user, context) < min_score.to_f
    end
  end

  def outcome_for(user, context = nil)
    return nil unless pass_fail?

    score = adjusted_score_for(user, context)
    return nil if score.nil?

    score >= PASS_MARK ? "通过" : "未通过"
  end

  def adjustment_factor_for(user, context = nil)
    return 1 unless group_work?
    return context.adjustment_factor(self, user) if context

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
