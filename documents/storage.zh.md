# 附件存储

附件默认写本地磁盘。设置 `STORAGE_PROVIDER=s3` 后写入 S3 兼容对象存储。

首版支持 AWS S3、Cloudflare R2、MinIO。阿里云 OSS 与七牛需要各自的服务商 gem，在 `config/initializers/carrierwave.rb` 增加分支后接入。

## 桶的划分

| 桶 | 内容 | 读权限 |
|---|---|---|
| 公开桶 | 课程封面、资源视频 | 匿名可读 |
| 私有桶 | 作业提交附件 | 仅签名 URL，默认 10 分钟 |

公开桶只授予 `uploads/*` 的 GetObject 权限，不要授予 ListBucket。私有桶不开放匿名读。

程序不设置对象 ACL。公开读由桶策略控制，因此换服务商时不需要改代码。

## 配置

| 变量 | 必填 | 默认 | 说明 |
|---|---|---|---|
| `STORAGE_PROVIDER` | 否 | `local` | `local` 或 `s3` |
| `STORAGE_ACCESS_KEY_ID` | s3 | — | 访问密钥 |
| `STORAGE_SECRET_ACCESS_KEY` | s3 | — | 访问密钥 |
| `STORAGE_REGION` | 否 | `us-east-1` | R2 填 `auto` |
| `STORAGE_ENDPOINT` | 否 | AWS 默认 | R2 与 MinIO 必填 |
| `STORAGE_PATH_STYLE` | 否 | `false` | MinIO 与 R2 填 `true` |
| `STORAGE_PUBLIC_BUCKET` | s3 | — | 公开桶名 |
| `STORAGE_PRIVATE_BUCKET` | s3 | — | 私有桶名 |
| `STORAGE_PUBLIC_HOST` | 否 | 服务商默认 | CDN 或 R2 公开域名 |
| `STORAGE_SIGNED_URL_TTL` | 否 | `600` | 私有文件签名有效秒数 |

缺少必填变量时，启动直接失败，不会静默回退本地。

## 示例

AWS S3：

```bash
export STORAGE_PROVIDER=s3
export STORAGE_ACCESS_KEY_ID="..."
export STORAGE_SECRET_ACCESS_KEY="..."
export STORAGE_REGION="ap-southeast-1"
export STORAGE_PUBLIC_BUCKET="edu-tech-public"
export STORAGE_PRIVATE_BUCKET="edu-tech-private"
```

Cloudflare R2：

```bash
export STORAGE_PROVIDER=s3
export STORAGE_ACCESS_KEY_ID="..."
export STORAGE_SECRET_ACCESS_KEY="..."
export STORAGE_REGION="auto"
export STORAGE_ENDPOINT="https://<account>.r2.cloudflarestorage.com"
export STORAGE_PATH_STYLE="true"
export STORAGE_PUBLIC_BUCKET="edu-tech-public"
export STORAGE_PRIVATE_BUCKET="edu-tech-private"
export STORAGE_PUBLIC_HOST="https://pub-<hash>.r2.dev"
```

MinIO：

```bash
export STORAGE_PROVIDER=s3
export STORAGE_ACCESS_KEY_ID="minioadmin"
export STORAGE_SECRET_ACCESS_KEY="minioadmin"
export STORAGE_REGION="us-east-1"
export STORAGE_ENDPOINT="http://127.0.0.1:9000"
export STORAGE_PATH_STYLE="true"
export STORAGE_PUBLIC_BUCKET="edu-tech-public"
export STORAGE_PRIVATE_BUCKET="edu-tech-private"
```

MinIO 建桶与匿名读：

```bash
mc alias set local http://127.0.0.1:9000 minioadmin minioadmin
mc mb local/edu-tech-public local/edu-tech-private
mc anonymous set download local/edu-tech-public
```

## 切换与回退

改环境变量后重启 Web 与后台作业。

切回本地：

```bash
unset STORAGE_PROVIDER
```

已写入对象存储的文件不会自动搬回本地。数据库只存文件名，切换存储后旧文件不可读。

当前没有迁移本地存量附件的任务。数据库里附件记录为 0，因此不做迁移。

## 限制

| 限制 | 说明 |
|---|---|
| 上传经过 Rails | 200 MB 视频占用一个 Puma 线程；未做浏览器直传 |
| 签名 URL 会过期 | 私有附件默认 10 分钟；过期后刷新页面重新生成 |
| 公开文件缓存 1 小时 | 同名替换封面后，浏览器可能继续用旧图 |
| 每环境一套桶 | 不支持按课程分桶 |

## 排错

| 现象 | 原因 | 处理 |
|---|---|---|
| 启动报 `STORAGE_PROVIDER=s3 requires ...` | 缺少必填变量 | 补齐访问密钥与两个桶名 |
| `Fog::Storage::AWS::NotFound` | 桶不存在 | 先在服务商侧建桶 |
| 封面 403 | 公开桶未开匿名读 | 配置桶策略，或检查 `STORAGE_PUBLIC_HOST` |
| 提交附件 403 | 签名过期 | 刷新页面 |
| MinIO 报签名错误 | 未用 path style | 设 `STORAGE_PATH_STYLE=true` |
| R2 封面地址仍是私有端点 | 未设公开域名 | 设 `STORAGE_PUBLIC_HOST` |

## 已验证

2026-11-12：

- 本地模式 227 runs / 672 assertions 全绿
- 用本地 S3 兼容端点验证公开桶与私有桶的 PUT、COPY、HEAD、DELETE
- 私有附件生成 600 秒签名 URL；公开封面使用 `STORAGE_PUBLIC_HOST`
- 未连接真实云厂商桶
