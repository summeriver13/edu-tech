class ApplicationUploader < CarrierWave::Uploader::Base
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def url(*args)
    return super unless public_asset? && file.respond_to?(:public_url)

    file.public_url || super
  end

  def fog_directory
    ENV.fetch(public_asset? ? "STORAGE_PUBLIC_BUCKET" : "STORAGE_PRIVATE_BUCKET")
  end

  def fog_attributes
    if public_asset?
      { "Cache-Control" => "public, max-age=3600" }
    else
      { "Cache-Control" => "private, max-age=0" }
    end
  end

  def asset_host
    ENV["STORAGE_PUBLIC_HOST"].presence&.delete_suffix("/") if public_asset?
  end

  def public_asset?
    false
  end
end
