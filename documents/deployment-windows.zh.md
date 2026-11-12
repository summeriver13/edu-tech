# Windows 部署（测试用）

本文用于在本机或内网 Windows 机器上跑完整应用做测试。公网部署与容量估算见 [performance.zh.md](./performance.zh.md)。

## 与 Linux 的差异

| 项 | Linux | Windows |
|---|---|---|
| Puma 多进程 | `fork` 可用，按 CPU 核数开 worker | 无 `fork`，只能单进程 |
| 反向代理 | nginx | 无 nginx 原生版本，用 Caddy、WSL2 或 IIS |
| 信号 | `SIGUSR1`/`SIGUSR2`/`SIGHUP` 可用 | 未实现，用文件触发重启（见「重启」） |
| Solid Queue | `fork` 监督进程 | 只能用 `--mode async` 线程模式 |
| 服务管理 | systemd | 任务计划程序或 NSSM |

## 前置

要求 Ruby 4.0.7、Node.js 24、Yarn 1。

```bash
bundle install
yarn install
yarn build && yarn build:css
```

`config/puma.rb` 在 Windows 上自动跳过 worker，不要设置大于 0 的 `WEB_CONCURRENCY`。

## 方案 A：Puma 直接服务

最少依赖，适合功能测试。

```bash
export RAILS_ENV=production
export SECRET_KEY_BASE="$(bin/rails secret)"
export FORCE_SSL=false

bin/rails db:prepare
SKIP_CSS_BUILD=1 bin/rails assets:precompile
bin/rails server -p 3100 -b 127.0.0.1
```

说明：

| 设置 | 作用 |
|---|---|
| `FORCE_SSL=false` | 允许 HTTP 测试。默认 `true`，请求会 301 到 HTTPS |
| `SKIP_CSS_BUILD=1` | 跳过 cssbundling 的工具探测。Windows 上该探测失败，CSS 需先由 `yarn build:css` 生成 |
| `db:prepare` | 建库、跑迁移并写入演示数据；空库时自动执行种子 |
| `assets:precompile` | 生产环境不现场编译资源，缺资源会返回 500 |

静态资源由 Rails 直接发送。单进程即可完成测试。

验证：

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3100/up
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3100/courses
```

两个请求都应返回 `200`。

## 后台作业

生产环境用 Solid Queue。Windows 无 `fork`，默认模式会抛 `NotImplementedError: fork() function is unimplemented`。

```bash
export RAILS_ENV=production
export SECRET_KEY_BASE="..."
bin/jobs --mode async
```

`--mode async` 用线程代替进程。调度器、dispatcher、worker 都在同一进程内。

不启动该进程时，仓库同步会停在队列里，页面显示「同步中」。

单次执行可用：

```bash
bin/rails runner 'CourseSyncJob.perform_now(Course.first.id)'
```

## 重启

Puma 支持按文件重启。`bin/rails restart` 写入 `tmp/restart.txt`，Puma 每 2 秒检查一次。

```bash
export RAILS_ENV=production
bin/rails restart
```

也可以直接 `touch tmp/restart.txt`，省去启动 Rails 命令的时间。

重启后 PID 改变，端口和绑定地址沿用启动参数。新进程就绪前，新请求会失败数秒。

`config/puma.rb` 在 Windows 上设置 `restart_command`。Puma 默认用 `$0` 和参数重建命令，但 Windows 不能直接执行无扩展名的 `bin/rails`，重建的命令也缺少 `server` 子命令。`restart_command` 补上这两点。

| 限制 | 说明 |
|---|---|
| Ruby 路径含空格 | Puma 按空格拆分 `restart_command`，路径会被拆断。改为停止再启动 |
| 参数含空格 | 同上。避免在 `-b` 等参数里使用空格 |
| 不是零停机 | 单进程重启。重启期间新连接失败数秒 |

不要用 `kill -INT`。Windows 上它会向整个控制台进程组发送 Ctrl+C，可能连同启动脚本一起结束。停止进程用 `Process.kill("KILL", pid)` 或任务管理器的「结束任务」。

后台作业不随 Puma 重启。前台运行时按 Ctrl+C，再重新执行：

```bash
bin/jobs --mode async
```

任务计划程序启动时，先「结束」任务，再「运行」任务。

## 方案 B：Caddy 反向代理

Caddy 有 Windows 原生版本，自动管理证书。适合验证代理头、TLS 与 Host 行为。

```bash
scoop install caddy
```

HTTPS 配置（推荐）：

```caddyfile
{
    admin off
}

https://localhost {
    tls internal
    reverse_proxy 127.0.0.1:3100
}
```

只做 HTTP 时用：

```caddyfile
{
    admin off
}

http://localhost:8080 {
    reverse_proxy 127.0.0.1:3100
}
```

HTTP 配置需同时设 `FORCE_SSL=false`。否则 Rails 会把请求 301 到同一端口的 https，而该端口不提供 TLS。

启动：

```bash
caddy trust
caddy run --config Caddyfile
```

`admin off` 关闭管理端口 2019，避免多次启动冲突。`tls internal` 使用本地 CA，`caddy trust` 需管理员权限。Caddy 转发 `X-Forwarded-Proto: https`，HTTPS 配置下 Rails 可保持 `FORCE_SSL` 默认值。

Caddy 标准版不带共享缓存。匿名页缓存仍由应用的 `Cache-Control: public, max-age=120` 控制。需要 nginx 式 `proxy_cache` 时用方案 C。

## 方案 C：WSL2 + nginx

需要验证 nginx 配置时使用。先安装 WSL2 与一个 Linux 发行版。

推荐把 Rails、SQLite 与 nginx 全部放在 WSL2 内，按 Linux 方式部署。跨文件系统访问 `/mnt/f` 很慢，不要用它跑数据库。

只把 nginx 放在 WSL2、应用留在 Windows 时，nginx 需指向 Windows 主机地址：

```bash
ip route show default | awk '{print $3}'
```

把输出的地址填入 `proxy_pass http://<地址>:3100;`。

WSL2 内可用 Linux 版 Ruby，也可只装 nginx。若只装 nginx，Windows 防火墙需允许 3100 端口。

## 方案 D：IIS

企业环境已有 IIS 时，可用 ARR、URL Rewrite 与 HttpPlatformHandler 反向代理。配置项多，本仓库未验证。测试优先选 A 或 B。

## 开机自启

任务计划程序建两个任务，工作目录设为仓库根目录。“程序”填 Ruby 全路径（如 `C:\Ruby40-x64\bin\ruby.exe`），“参数”填：

| 任务 | 参数 |
|---|---|
| Web | `bin\rails server -p 3100 -b 127.0.0.1` |
| Jobs | `bin\jobs --mode async` |

两个任务都需设置 `RAILS_ENV=production`、`SECRET_KEY_BASE`，Web 任务另设 `FORCE_SSL`。

## 已知限制

| 限制 | 说明 |
|---|---|
| 单进程 | 无 `fork`。吞吐上限见 performance.zh.md 的压测结果 |
| 无信号式重启 | `SIGUSR1`/`SIGUSR2` 未实现。用 `bin/rails restart`；后台作业单独重启 |
| 附件默认落本机 | 默认 CarrierWave 写入 `public/uploads/`。多机部署前设置 `STORAGE_PROVIDER=s3`，见 storage.zh.md |
| SQLite 单写者 | 高并发写入时改用 PostgreSQL 与 `DATABASE_URL` |
| 无共享缓存 | Caddy 标准版不带缓存；匿名页缓存靠响应头 |

## 排错

| 现象 | 原因 | 处理 |
|---|---|---|
| `fork() function is unimplemented` | Solid Queue 默认 fork 模式 | 加 `--mode async` |
| `SIGUSR2 not implemented` | Windows 无该信号 | 正常现象，可忽略 |
| `cssbundling-rails: No suitable tool found` | 工具探测失败 | 先 `yarn build:css`，再 `SKIP_CSS_BUILD=1` |
| 页面 500，日志报缺少表 | 数据库未建 | `bin/rails db:prepare` |
| 页面无样式，CSS 404 | 未预编译 | `SKIP_CSS_BUILD=1 bin/rails assets:precompile` |
| 请求 301 到 HTTPS | `force_ssl` 默认开启 | 本地测试设 `FORCE_SSL=false`，或前置 Caddy |

## 已验证

2026-11-11，Windows，Rails 8.1.4.1、Ruby 4.0.7、Puma 8.0.2，生产模式单进程：

```
/up          200
/courses     200，6612 字节
/assets/*.css 200，text/css
默认 FORCE_SSL：/courses 301 到 https://
bin/jobs --mode async：Supervisor、Dispatcher、Worker、Scheduler 全部启动
Caddy 2.11.9：https://localhost/courses 200；HTTP 配置在 FORCE_SSL=false 下 200
bin/rails restart：PID 33896 → 5272，仍监听 3117，/up 200
```
