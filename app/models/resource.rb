class Resource < ApplicationRecord
  belongs_to :course
  mount_uploader :video, ResourceUploader

  validates :name, :resource_type, presence: true
end
