class Submission < ApplicationRecord
  belongs_to :assessment
  belongs_to :user
  belongs_to :group, optional: true
  belongs_to :deliverable, optional: true
  has_one :grade, dependent: :destroy

  mount_uploader :file, SubmissionUploader

  validate :owner_uniqueness
  validate :group_presence
  validate :group_size_within_bounds
  validate :deliverable_belongs_to_assessment
  validate :body_or_file_present

  after_destroy :remove_file

  def due_at
    deliverable&.due_at || assessment&.due_at
  end

  def late_days
    deadline = due_at
    return 0 if deadline.nil? || updated_at.nil?

    seconds = updated_at.to_f - deadline.to_f
    return 0 if seconds <= 0

    (seconds / 1.day).ceil
  end

  def word_count
    body.to_s.split.size
  end

  private

  def owner_uniqueness
    scope = Submission.where(assessment_id: assessment_id, deliverable_id: deliverable_id).where.not(id: id)
    scope = group_id.present? ? scope.where(group_id: group_id) : scope.where(user_id: user_id)
    errors.add(:base, "已经提交过了。") if scope.exists?
  end

  def group_size_within_bounds
    return unless assessment&.group_work?
    return if group.nil?

    size = group.group_memberships.count
    minimum = assessment.group_min
    maximum = assessment.group_max
    return if (minimum.nil? || size >= minimum) && (maximum.nil? || size <= maximum)

    errors.add(:group, "人数必须在 #{[ minimum, maximum ].compact.join("–")} 人之间")
  end

  def deliverable_belongs_to_assessment
    return if deliverable.nil? || deliverable.assessment_id == assessment_id

    errors.add(:deliverable, "不属于该评估")
  end

  def group_presence
    return unless assessment&.group_work?
    return if group_id.present?

    errors.add(:group, "必须选择小组")
  end

  def body_or_file_present
    return if body.present? || file.present?

    errors.add(:base, "请填写内容或上传附件")
  end

  def remove_file
    file.remove! if file.present?
  end
end
