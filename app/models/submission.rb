class Submission < ApplicationRecord
  belongs_to :assignment
  belongs_to :user

  mount_uploader :file, SubmissionUploader

  validates :user_id, uniqueness: { scope: :assignment_id }
  validate :body_or_file_present

  after_destroy :remove_file

  private

  def body_or_file_present
    return if body.present? || file.present?

    errors.add(:base, "请填写内容或上传附件")
  end

  def remove_file
    file.remove! if file.present?
  end
end
