class CoverUploader < ApplicationUploader
  def extension_allowlist
    %w[ jpg jpeg png webp ]
  end

  def public_asset?
    true
  end
end
