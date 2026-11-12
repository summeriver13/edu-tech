# change-log 更新日志

## bofore start

## 2024/3/20 add Bootstrap

选择使用Bootstrap框架作为“前端框架”。

### Bootstrap 安装

rails 7 原生支持bootstrap，所以可以在构建新项目的时候直接通过设置来安装启用Bootstrap。

具体指令如下：

```
rails new edu-tech -c bootstrap -j esbuild
```

在学习如何在rails中引入Bootstrap的过程中踩了一些坑。

- [Rails 7 如何安装 Bootstrap](https://www.bilibili.com/video/BV1w84y1p7eq)

主要的问题是由于rails默认选择importmap这项技术导致的。
解决方案就是绕过去，项目创建时直接选择esbuild而非默认的。

- [Bootstrap 5 + esbuild in Ruby on Rails 7](https://www.youtube.com/watch?v=jyqjecyCv3A)

## 2026/11/9 storage switch and upgrade

- Storage: Qiniu Cloud (expired) -> local CarrierWave `storage :file`, files in `public/uploads/`
- Ruby 3.2.3 -> 4.0.7; Rails 7.1.3 -> 8.1.4.1; `config.load_defaults 8.1`
- Fixes: Course associations use `dependent: :destroy`; added missing `courses#edit` view; fixtures use real data; `fiddle`/`irb` added for Ruby 4 console

## 2026/11/12 object storage

- Attachments can use S3-compatible object storage: AWS S3, Cloudflare R2, MinIO
- Public bucket: course covers and resource videos. Private bucket: submission files with 10-minute signed URLs
- Default remains local `public/uploads/`; existing files were not migrated (0 attachment records)

## 2026/11/12 CDN cache

- Anonymous course list, course page and lesson page send `CDN-Cache-Control` with a 300-second edge TTL
- Logged-in and form responses default to `private, no-store`
- Document Cloudflare cache rules and the session-cookie bypass


