class Resource < ApplicationRecord
  belongs_to :course
  mount_uploader :video, ResourceUploader

  validates :name, :resource_type, presence: true
  validate :url_or_video_present

  after_destroy :remove_video_file

  private

  def url_or_video_present
    return if url.present? || video.present?

    errors.add(:base, "请提供链接或视频文件")
  end

  def remove_video_file
    video.remove! if video.present?
  end
end
