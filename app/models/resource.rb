class Resource < ApplicationRecord
  belongs_to :course
  mount_uploader :video, ResourceUploader
  mount_uploader :image, ResourceUploader
end
