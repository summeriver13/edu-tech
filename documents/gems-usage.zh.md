# gems 使用说明

## ruby版本

```ruby
ruby "3.2.3"
```

## rails

> Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"

```ruby
gem "rails", "~> 7.1.3", ">= 7.1.3.2"
```

## sprockets-rails

> The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]

```ruby
gem "sprockets-rails"
```

## qiniu 七牛云 ruby SDK

> Use qiniu-cloud stroge files. [https://developer.qiniu.com/kodo/1304/ruby]

```ruby
gem "qiniu", ">= 6.9.1"
```

## carrierwave 更好的文件上传

> [https://github.com/huobazi/carrierwave-qiniu]

```ruby
gem 'carrierwave'
```

### carrierwave-qiniu 七牛云支持

> This gem adds storage support for Qiniu to Carrierwave [https://github.com/huobazi/carrierwave-qiniu]

```ruby
gem 'carrierwave-qiniu'
```

需要配置的地方较多，全部配置好才能正常上传文件七牛云。

### 加载uploads目录

> /config/application.rb

```ruby
config.autoload_paths += %W(#{config.root}/app/uploaders)
```

### 编写init加载文件

> /config/initializers/carrierwave.rb

```ruby
::CarrierWave.configure do |config|
  config.storage              = :qiniu
  config.qiniu_access_key     = ""
  config.qiniu_secret_key     = ''
  config.qiniu_bucket         = ""
  config.qiniu_bucket_domain  = ""
  config.qiniu_bucket_private = true #default is false
  config.qiniu_block_size     = 4*1024*1024
  config.qiniu_protocol       = "http"
end
```

### 编写uploader

> /app/uploaders/resource_uploader.rb

- 文件名(下划线命名法)： <文件名>_uploader.rb
- 类名（驼峰命名法）: <类名>Uploadder

```ruby
class ResourceUploader < CarrierWave::Uploader::Base
  storage :qiniu
end
```



##  sqlite3 关系型数据库

> Use sqlite3 as the database for Active Record

```ruby
gem "sqlite3", "~> 1.4"
```

## puma

> Use the Puma web server [https://github.com/puma/puma]

```ruby
gem "puma", ">= 5.0"
```

## jsbundling-rails

> Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]

```ruby
gem "jsbundling-rails"
```

## turbo-rails

> Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]

```ruby
gem "turbo-rails"
```

## stimulus-rails

> Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]

```ruby
gem "stimulus-rails"
```

## cssbundling-rails

> Bundle and process CSS [https://github.com/rails/cssbundling-rails]

```ruby
gem "cssbundling-rails"
```

## jbuilder

> Build JSON APIs with ease [https://github.com/rails/jbuilder]

```ruby
gem "jbuilder"
```

## redis 内存数据库 NoSQL

> Use Redis adapter to run Action Cable in production

```ruby
gem "redis", ">= 4.0.1"
```

### kredis

> Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]

```ruby
# gem "kredis"
```

## bcrypt

> Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword] 用户密码加密

```ruby
gem "bcrypt", "~> 3.1.7"
```

## tzinfo-data

> Windows does not include zoneinfo files, so bundle the tzinfo-data gem

```ruby
gem "tzinfo-data", platforms: %i[ windows jruby ]
```

## bootsnap

> Reduces boot times through caching; required in config/boot.rb

```ruby
gem "bootsnap", require: false
```

## image_processing

> Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]

```ruby
# gem "image_processing", "~> 1.2"
```

```ruby
group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
end
```

```ruby
group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end
```

```ruby
group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
```
