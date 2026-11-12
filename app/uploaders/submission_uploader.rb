class SubmissionUploader < ApplicationUploader
  MAX_FILE_SIZE = 50.megabytes
  ALLOWED_EXTENSIONS = %w[ pdf zip txt md docx pptx png jpg jpeg ].freeze

  def extension_allowlist
    ALLOWED_EXTENSIONS
  end

  def size_range
    0..MAX_FILE_SIZE
  end
end
