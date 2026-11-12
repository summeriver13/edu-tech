provider = ENV["STORAGE_PROVIDER"].presence || "local"

case provider
when "local"
  CarrierWave.configure { |config| config.storage = :file }
when "s3"
  require "fog/aws"

  required = %w[STORAGE_ACCESS_KEY_ID STORAGE_SECRET_ACCESS_KEY STORAGE_PUBLIC_BUCKET STORAGE_PRIVATE_BUCKET]
  missing = required.select { |key| ENV[key].blank? }
  raise "STORAGE_PROVIDER=s3 requires #{missing.join(", ")}" if missing.any?

  credentials = {
    provider: "AWS",
    aws_access_key_id: ENV.fetch("STORAGE_ACCESS_KEY_ID"),
    aws_secret_access_key: ENV.fetch("STORAGE_SECRET_ACCESS_KEY"),
    region: ENV.fetch("STORAGE_REGION", "us-east-1")
  }
  endpoint = ENV["STORAGE_ENDPOINT"].presence
  credentials[:endpoint] = endpoint.delete_suffix("/") if endpoint
  credentials[:path_style] = ENV["STORAGE_PATH_STYLE"] == "true"

  CarrierWave.configure do |config|
    config.storage = :fog
    config.fog_credentials = credentials
    config.fog_public = false
    config.fog_authenticated_url_expiration = Integer(ENV.fetch("STORAGE_SIGNED_URL_TTL", 600))
  end
else
  raise "Unsupported STORAGE_PROVIDER=#{provider}. Use local or s3."
end
