class Submission < ApplicationRecord
  belongs_to :assessment
  belongs_to :user
  belongs_to :group, optional: true
  has_one :grade, dependent: :destroy

  mount_uploader :file, SubmissionUploader

  validate :owner_uniqueness
  validate :group_presence
  validate :body_or_file_present

  after_destroy :remove_file

  private

  def owner_uniqueness
    scope = Submission.where(assessment_id: assessment_id).where.not(id: id)
    scope = group_id.present? ? scope.where(group_id: group_id) : scope.where(user_id: user_id)
    errors.add(:base, "已经提交过了。") if scope.exists?
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
