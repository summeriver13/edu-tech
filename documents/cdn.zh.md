# CDN 缓存

当前不接 CDN。源站保留缓存头，供将来接入时使用。

匿名课程页面由共享缓存缓存。源站给出缓存头，CDN 决定是否缓存与缓存多久。浏览器每次回源复查，不保存匿名页面。

登录页面、表单与个人数据不进 CDN。接入 CDN 后必须先按会话 Cookie 绕过缓存。

## 缓存策略

| 页面 | Cache-Control | CDN-Cache-Control |
|---|---|---|
| 课程列表、课程页、课时页（匿名） | `max-age=0, public, s-maxage=300` | `public, max-age=300, stale-while-revalidate=60, stale-if-error=600` |
| 登录后的同一页面 | `max-age=0, private, must-revalidate` | `private, no-store` |
| 登录、表单、提交、成绩等 | Rails 默认私有头 | `private, no-store` |

含义：

- 浏览器不缓存匿名页面，每次带 `ETag` 回源复查，命中返回 304。
- 共享缓存与 CDN 缓存 300 秒。当前未接 CDN 时，`s-maxage` 与 `CDN-Cache-Control` 不生效。
- 过期后 60 秒内可先返回旧内容并在后台复查。
- 源站 5xx 时最多再用旧内容 600 秒。
- `ETag` 与 `Last-Modified` 已存在，CDN 复查可得到 304。

匿名响应不设置 `Set-Cookie`。测试已断言。

公共页不渲染 `csrf_meta_tags`，课程搜索表单为 GET 且不带 token。否则 Rails 会写会话 Cookie，CDN 不缓存该响应。

## 为什么不用 nginx

nginx 的 Windows 构建是 beta，功能受限，不适合作为生产目标。本地测试 nginx 还要装 WSL 或虚拟机。

Caddy 标准版没有 HTTP 缓存模块。

CDN 不依赖本机反向代理。源站输出正确的缓存头，CDN 侧配置规则即可。Linux 生产环境仍可用 nginx `proxy_cache`，缓存头兼容。

## Cloudflare 配置

以下是将来接入时的配置，以 Cloudflare 为例。

### 1. 代理 DNS

把站点记录设为 Proxied（橙色云）。源站保持 HTTPS。

### 2. 先建绕过规则

顺序放在缓存规则之前。

| 项 | 值 |
|---|---|
| 规则名 | Bypass logged-in |
| 表达式 | `http.cookie contains "_app1_session"` |
| 操作 | Bypass cache |

`_app1_session` 是当前 Rails 会话 Cookie 名。改名后同步修改此规则。

没有这条规则时，CDN 可能把匿名页面返回给登录用户。

### 3. 再建缓存规则

| 项 | 值 |
|---|---|
| 规则名 | Cache public course pages |
| 表达式 | `http.request.method eq "GET" and (http.request.uri.path eq "/courses" or starts_with(http.request.uri.path, "/courses/"))` |
| Cache eligibility | Eligible for cache |
| Edge TTL | Use cache-control header if present, bypass cache if not |
| Browser TTL | Respect origin |

不要选 “Ignore cache-control header and use this TTL”。它会忽略源站的 `private, no-store`，可能缓存登录页面。

Cloudflare 的 Origin Cache Control 对 Free、Pro、Business 默认开启。开启时 `CDN-Cache-Control` 优先于 `Cache-Control`。

### 4. 查询串

默认缓存键包含查询串。`/courses?q=Rails` 与 `/courses?page=2` 分开缓存。

不要忽略查询串，否则搜索结果会串页。

## 验证

真实域名放在部署环境变量里，不写进仓库。示例：

```bash
export ORIGIN_HOST=https://origin.example
export CDN_HOST=https://cdn.example
```

源站：

```bash
curl -sI "$ORIGIN_HOST/courses" |
  rg -i 'cache-control|cdn-cache-control|set-cookie'
```

期望：

```text
cache-control: max-age=0, public, s-maxage=300
cdn-cache-control: public, max-age=300, stale-while-revalidate=60, stale-if-error=600
```

没有 `set-cookie`。

经过 CDN：

```bash
curl -sI "$CDN_HOST/courses" | rg -i 'cf-cache-status|cache-control'
```

第一次通常为 `MISS`，第二次为 `HIT`。

带会话 Cookie：

```bash
curl -sI -H 'Cookie: _app1_session=test' "$CDN_HOST/courses" |
  rg -i 'cf-cache-status'
```

期望 `DYNAMIC` 或 `BYPASS`，不是 `HIT`。

## 失效

当前没有 CDN，课程同步后改动立即生效；浏览器每次回源复查。

接入 CDN 后，旧页面最多保留 300 秒，再加 60 秒 stale 窗口。

需要立即更新时，在 CDN 控制台按 URL 清除：

- `/courses`
- `/courses/<id>`
- `/courses/<id>/lessons/<id>`

当前没有自动清除任务。课程同步完成后手动清除，或等 TTL 过期。

## 调优

参数在 `app/controllers/concerns/public_cache.rb`：

| 常量 | 默认 | 作用 |
|---|---|---|
| `BROWSER_MAX_AGE` | 0 | 浏览器缓存秒数；0 表示每次回源复查 |
| `EDGE_MAX_AGE` | 300 | CDN 缓存秒数 |
| `STALE_WHILE_REVALIDATE` | 60 | 过期后后台复查的宽限 |
| `STALE_IF_ERROR` | 600 | 源站故障时使用旧内容的上限 |

TTL 越短，课程改动越快生效；TTL 越长，源站压力越小。

## 已验证

2026-11-12：

- 本地 234 runs / 736 assertions 全绿
- 生产模式 Puma 实测 `/courses` 与 `/courses/1` 返回公开缓存头，且没有 `Set-Cookie`
- 未在真实 Cloudflare 账户上验证

2026-11-13：

- 决定暂不接入 CDN
- 浏览器缓存改为 `max-age=0`，匿名页面每次用 `ETag` 复查
- 保留 `s-maxage` 与 `CDN-Cache-Control`，供将来接入共享缓存

## 限制

- 当前未接 CDN；只有源站条件请求生效，匿名页面仍回源。
- 真实域名只放部署环境变量，不写入仓库。
- 只缓存课程列表、课程页、课时页。首页含登录入口，不缓存。
- 接入 CDN 后，登录用户的请求必须绕过 CDN。
- 没有自动 purge。课程同步后可能短暂显示旧内容。
- CDN 必须支持 `CDN-Cache-Control`，或至少遵守 `Cache-Control` 的 `s-maxage`。
- 未在真实 Cloudflare 账户上验证。源站头与 304 已由集成测试覆盖。
