class ResourceUploader < CarrierWave::Uploader::Base
  MAX_FILE_SIZE = 200.megabytes
  ALLOWED_EXTENSIONS = %w[ mp4 webm mov m4v ].freeze

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    ALLOWED_EXTENSIONS
  end

  def size_range
    0..MAX_FILE_SIZE
  end
end
