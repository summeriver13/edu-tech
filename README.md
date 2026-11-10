# eud-tech

[Rails](https://rubyonrails.org),
[Bootstrap](https://getbootstrap.com),
[PostgreSQL](https://www.postgresql.org),

## quick-links

## quick-start

要求：Ruby 4.0.7（见 `.ruby-version`）、Node.js 24（见 `.node-version`）+ Yarn 1。

```
bundle install
yarn install
yarn build && yarn build:css
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

演示数据：3 门课程、4 个资源、3 个活动；登录账号 `admin` / `secret`（管理员）与 `member` / `secret`（普通用户）。

运行测试：`bin/rails test`。Windows 下 cssbundling-rails 的工具探测缺陷会让 `test:prepare` 失败，先手动 `yarn build:css`，再用 `SKIP_CSS_BUILD=1 bin/rails test`。

## documents

- [rails-guide.zh.md](./documents/rails-guide.zh.md)
- [change-log.zh.md](./documents/change-log.zh.md)

## storage

- 本地文件存储（CarrierWave `storage :file`），文件写入 `public/uploads/`，不入库
