class ResourceUploader < CarrierWave::Uploader::Base
  storage :qiniu
end
