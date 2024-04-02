require 'qiniu'

Qiniu.establish_connection! access_key: '0UHnMYqWItMk_9iDZIkTcjW_YcMR7UU5prT7rBZt',
                            secret_key: 'o_kS6RVesdMowl2eJam49OQcLg4YYFMjyL_mudWO'

Rails.application.config.qiniu_domain = "qiniu.summeriver.tech"
