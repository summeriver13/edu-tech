# 数据库适配器

## 决定

平台支持两种适配器。SQLite 是默认值。PostgreSQL 是可选值。

| 适配器 | 用途 | 开启方式 |
|---|---|---|
| SQLite | 单机部署，默认 | 不设 `DATABASE_URL` |
| PostgreSQL | 多节点部署，并发写 | 设 `DATABASE_URL`，并装 `pg` |

## 开启 PostgreSQL

```bash
BUNDLE_WITH=postgres bundle install
export DATABASE_URL=postgres://user:password@host:5432/edu_tech_production
export QUEUE_DATABASE_URL=postgres://user:password@host:5432/edu_tech_queue  # 可选
bin/rails db:prepare
```

`pg` 在 `Gemfile` 的 `postgres` 可选组内。默认安装不拉取该组，所以本地 SQLite 开发不受影响。

`config/database.yml` 的 `production` 段用 `url` 覆盖 `database`。主库读 `DATABASE_URL`，队列库读 `QUEUE_DATABASE_URL`。任一为空时回退到同目录的 SQLite 文件。

## 兼容性规则

迁移与模型只写两种适配器都支持的 SQL。

| 规则 | 理由 |
|---|---|
| 模糊搜索用 `LOWER(column) LIKE LOWER(:pattern)` | PostgreSQL 的 `LIKE` 区分大小写，SQLite 不区分 |
| 随机取样用 `RANDOM()` | 两个适配器都支持 |
| 部分索引用 `where:` | 两个适配器都支持 |
| 不写 `PRAGMA`、`strftime`、`julianday` | 仅 SQLite 可用 |
| JSON 列用 `t.json` | 两个适配器都支持 |

## 验证

CI 有两个测试作业。`test` 跑 SQLite。`test-postgres` 跑 PostgreSQL 16，并设置 `DATABASE_URL` 与 `BUNDLE_WITH=postgres`。两个作业都必须通过。

## 回滚

删除 `DATABASE_URL` 后重启。平台回到 SQLite。数据库文件不受影响。

## 取舍

| 方案 | 得到 | 代价 |
|---|---|---|
| 只用 SQLite | 零运维，单文件可携带 | 单写者，不能多节点 |
| 只用 PostgreSQL | 多写者，多节点 | 运维成本，本地开发变重 |
| 双适配器（本方案） | 默认轻，按需扩展 | 每次迁移要过两个作业 |

## 已知限制

出勤门槛、外部系统对接等能力与适配器无关，见 `documents/course-model.zh.md`。
