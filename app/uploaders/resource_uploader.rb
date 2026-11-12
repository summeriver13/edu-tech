class ResourceUploader < ApplicationUploader
  MAX_FILE_SIZE = 200.megabytes
  ALLOWED_EXTENSIONS = %w[ mp4 webm mov m4v ].freeze

  def extension_allowlist
    ALLOWED_EXTENSIONS
  end

  def size_range
    0..MAX_FILE_SIZE
  end

  def public_asset?
    true
  end
end
