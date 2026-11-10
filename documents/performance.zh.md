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
| 公共缓存 | 匿名响应 `Cache-Control: public, max-age=120`；登录响应为 `private` |
| 同步转入后台 | `CourseSyncJob` 执行 git 拉取，Web 线程不再等待 |

## 并发只读部署

单进程 Puma 无法承接一万并发。按下面三层部署。

1. 反向代理或 CDN 缓存匿名页面。`Cache-Control: public, max-age=120` 已由应用给出。`ETag` 让代理用 304 复查。
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
| 大列表分页 | 题库、贡献台账、成员列表仍全量加载 |
| 全文搜索 | 只做 `LIKE` 前缀包含匹配 |
| 附件对象存储 | 附件仍在 `public/uploads/` |
| 缓存组件 | 未引入 Solid Cache。预渲染后片段缓存收益很小 |
