# 课程仓库约定

每门课程可以关联一个 git 仓库。仓库存教学内容，数据库存人员与互动。

## 目录结构

```
course.yml          # 必需：课程元数据与资源/活动清单
docs/               # 讲义（Markdown 等）
media/              # 小文件素材
```

## course.yml

```yaml
course:
  title: 数据库系统
  description: 关系模型与 SQL
  credit: 3

resources:
  - name: 仓库讲义
    type: document
    url: https://example.com/handout.pdf

activities:
  - type: 直播
    start: 2026-03-02T19:00:00+08:00
    end: 2026-03-02T20:30:00+08:00
    location: 线上
```

| 字段 | 说明 |
|---|---|
| `course.title` / `course.description` / `course.credit` | 可选；只覆盖这三个字段，`course_number` 不动 |
| `resources[].name` | 必需；同名资源视为同一条，更新其余字段 |
| `resources[].type` | 写入 `resource_type` |
| `resources[].url` | 必需；当前不支持从仓库导入文件 |
| `activities[].type` + `start` | 必需；两者共同定位一条活动 |
| `activities[].end` / `location` / `description` | 可选 |

## 同步规则

- 触发方式：课程页「从仓库同步」按钮；只有管理员、`teacher`、`assistant`、`maintainer` 可见。
- 拉取方式：首次 `git clone --depth 1`，之后 `git fetch --depth 1` + `reset --hard FETCH_HEAD`；克隆目录 `storage/repos/<course_number>`。
- 写入方式：按名称/类型更新或新建，**不删除**数据库中 manifest 已移除的记录。
- 事务：课程字段、资源、活动、`commit_sha`、`synced_at` 在同一事务内提交；任一步失败整体回滚并提示原因。

## 权限

| 角色 | 范围 |
|---|---|
| `admin` | 全局：所有课程与其子资源 |
| `teacher` / `assistant` / `maintainer` | 仅所属课程：编辑课程、同步、增删改资源与活动 |
| `student` | 只读 |
