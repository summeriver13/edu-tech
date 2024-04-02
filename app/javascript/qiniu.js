const qiniu = require('qiniu-js')

const ACCESS_KEY = '0UHnMYqWItMk_9iDZIkTcjW_YcMR7UU5prT7rBZt';
const SECRET_KEY = 'o_kS6RVesdMowl2eJam49OQcLg4YYFMjyL_mudWO';
const BUCKET_NAME = 'rails-videos';


const observable = qiniu.upload(file, key, token, putExtra, config)

const subscription = observable.subscribe(observer) // 上传开始

subscription.unsubscribe() // 上传取消
