require 'qiniu'

Qiniu.establish_connection! access_key: '',
                            secret_key: ''

Rails.application.config.qiniu_domain = ""
