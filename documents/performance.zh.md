# 性能

## 基线

测量环境：Rails 8.1.4、Ruby 4.0.7、SQLite 3.54.1（WAL，`synchronous=NORMAL`）、Windows 开发机。

测量数据：一篇 19 KB 课时正文，30 名学生 × 8 个评估。

| 场景 | 改动前 | 改动后 |
|---|---|---|
| 课时页（匿名） | 240 ms | 82 ms |
| 课时页（成员） | 226 ms | 72 ms |
| 成绩页（30 人 × 8 项） | 2,038 ms，1,969 条 SQL | 105 ms，14 条 SQL |
| 课程页（60 课时） | 223 ms，15 条 SQL | 未变 |
| 练习页 | 74 ms，5 条 SQL | 未变 |

## 已做的改动

| 改动 | 机制 |
|---|---|
| 课时正文预渲染 | 同步时写 `lessons.body_html`，请求只输出 HTML |
| 成绩页批量取数 | `ScoreContext` 一次加载提交、成绩、作答与小组系数 |
| 条件请求 | 课程页与课时页返回 `ETag` 与 `Last-Modified`，命中返回 304 |
| 公共缓存 | 匿名响应 `Cache-Control: max-age=0, public, s-maxage=300` 与 `CDN-Cache-Control`；浏览器每次用 ETag 复查，登录响应为 `private, no-store` |
| 同步转入后台 | `CourseSyncJob` 执行 git 拉取，Web 线程不再等待 |

## 并发压测

环境：AMD Ryzen 5 7500F，6 核 12 线程，Windows。服务端为 Puma 8.0.2 单进程、生产环境、SQLite。客户端为 Ruby `Net::HTTP` 多线程，与服务器同机。客户端占用同一台机器的 CPU，因此下面的数字是保守值。

页面：公开课时页，响应 32.6 KB（正文 19 KB 预渲染后）。

服务端 5 线程：

| 客户端线程 | 请求数 | RPS | p50 | p95 | p99 |
|---|---|---|---|---|---|
| 4 | 160 | 147 | 30 ms | 46 ms | 48 ms |
| 16 | 480 | 202 | 77 ms | 109 ms | 137 ms |
| 32 | 640 | 209 | 142 ms | 190 ms | 204 ms |

服务端 16 线程：

| 客户端线程 | 请求数 | RPS | p95 |
|---|---|---|---|
| 16 | 480 | 199 | 172 ms |
| 32 | 640 | 190 | 282 ms |
| 64 | 640 | 199 | 446 ms |

其他路径：

| 路径 | RPS | p95 |
|---|---|---|
| 条件请求命中（304） | 291 | 78 ms |
| 课程页（6.5 KB） | 127 | 171 ms |

结论：

1. 单进程吞吐约 200 RPS。服务端线程从 5 增到 16，RPS 不变，p95 上升，瓶颈是单进程 CPU。
2. 200 RPS × 32.6 KB 约为 6.5 MB/s。一万并发读者每两分钟刷新一次约 83 RPS，单进程没有余量。
3. 304 路径为 291 RPS。条件请求省掉渲染，但仍经过 Rails。
4. 匿名页面必须由反向代理或 CDN 承接。当前未接 CDN，单进程上限约 200 RPS，按缓存未命中和登录请求估算。

## 并发只读部署

单进程 Puma 无法承接一万并发。按下面三层部署。

1. 接入 CDN 后，优先用 CDN 缓存匿名页面。应用给出 `Cache-Control` 与 `CDN-Cache-Control`，`ETag` 让 CDN 用 304 复查。配置见 [cdn.zh.md](./cdn.zh.md)。当前未接 CDN，匿名页面仍回源。Linux 也可用 nginx `proxy_cache`。
2. Puma 线程数与数据库连接池对齐。默认 `RAILS_MAX_THREADS=5`。只读为主时可调到 8。
3. 多节点时用 PostgreSQL。SQLite 是单写者，写请求会串行。

示例 nginx 片段：

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=edu:100m max_size=2g inactive=10m;

server {
  location / {
    proxy_cache edu;
    proxy_cache_valid 200 120s;
    proxy_cache_revalidate on;
    proxy_pass http://127.0.0.1:3000;
  }
}
```

## 写入容量

SQLite 单线程实测 682 行/秒。8 线程并写降到 261 行/秒，并出现连接池超时。连接池默认 5，并发线程不得超过该值。

考试截止时的集中提交建议用 PostgreSQL。队列数据库与主库分开，避免后台任务争抢写锁。

## 后台任务

生产环境用 Solid Queue。启动命令：

```bash
bin/jobs
```

部署时先跑 `bin/rails db:prepare`，它会创建 `storage/production_queue.sqlite3` 或 `QUEUE_DATABASE_URL` 指向的库。

## 未做

| 项目 | 现状 |
|---|---|
| 全文搜索 | 只做 `LIKE` 前缀包含匹配 |
| 缓存组件 | 未引入 Solid Cache。预渲染后片段缓存收益很小 |
| CDN 自动清除 | 课程同步后靠 TTL 过期；未接 CDN purge API |
