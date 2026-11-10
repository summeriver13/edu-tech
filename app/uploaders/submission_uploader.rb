class SubmissionUploader < CarrierWave::Uploader::Base
  MAX_FILE_SIZE = 50.megabytes
  ALLOWED_EXTENSIONS = %w[ pdf zip txt md docx pptx png jpg jpeg ].freeze

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
