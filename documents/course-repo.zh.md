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

term:
  week1_start: 2026-08-31   # 第 1 周起始日
  time_zone: Australia/Sydney
  weeks: 18
  late_penalty:              # 可选
    percent_per_day: 5       # 每迟交一天扣的分数
    max_days: 4              # 超过该天数不给分
  census_at: 2026-10-05      # 可选
  min_attendance: 80         # 可选，百分数

activities:
  - type: 直播
    start: 2026-03-02T19:00:00+08:00
    end: 2026-03-02T20:30:00+08:00
    location: 线上

assessments:
  - key: quiz
    title: Quiz
    kind: quiz
    weight: 20
    group_work: false
    slos: [SLO1, SLO2]
    due_at: 2026-11-05T17:50:00+11:00
    scope: Lecture 1–6
    venue: 南湖 N201
  - key: group-project
    title: Group project
    kind: project
    weight: 30
    group_work: true
  - key: final-exam
    title: Final exam
    kind: exam
    weight: 50
```

| 字段 | 说明 |
|---|---|
| `course.title` / `course.description` / `course.credit` | 可选；只覆盖这三个字段，`course_number` 不动 |
| `term.week1_start` / `time_zone` / `weeks` | 可选；写入课程的第 1 周起始日、IANA 时区与学期周数 |
| `resources[].name` | 必需；同名资源视为同一条，更新其余字段 |
| `resources[].type` | 写入 `resource_type` |
| `resources[].url` | 必需；当前不支持从仓库导入文件 |
| `activities[].type` + `start` | 必需；两者共同定位一条活动 |
| `activities[].end` / `location` / `description` | 可选 |
| `assessments[].key` | 必需；课程内唯一，同步的定位键 |
| `assessments[].kind` | `quiz` / `exam` / `project` / `assignment` / `presentation` / `essay` / `lab`，缺省 `assignment` |
| `assessments[].weight` | 0–100；同一清单合计必须为 100，否则拒绝同步 |
| `assessments[].group_work` / `slos` / `scope` / `venue` / `opens_at` / `due_at` | 可选 |
| `assessments[].hurdle` / `min_score` | 可选。`hurdle: true` 表示门槛项：`min_score` 缺省为「只需提交」，否则低于该分即总评记 TF |
| `assessments[].pass_fail` | 可选；及格制只记通过 / 未通过（50 分为界） |
| `assessments[].sittings` / `best_of` | 可选；测验计划次数与计分次数，`best_of` 不能大于 `sittings` |
| `assessments[].word_limit` / `word_limit_tolerance` | 可选；字数要求与允许偏差，默认偏差 10% |
| `assessments[].group_min` / `group_max` | 可选；小组人数区间，提交时校验 |
| `assessments[].deliverables[]` | 可选；`name` 必需且评估内唯一，`due_at` 可选，按名称 upsert |
| `assessments[].ai_policy` | 可选；`not_permitted` 或 `allowed_with_declaration`，留空表示未规定 |
| `lessons[]` | 可选；`path` 必需且相对仓库根目录，`title` 可选，按路径 upsert |
| `questions[]` | 可选；`key` 必需且课程内唯一，`lesson` 按课时路径关联，按 `key` upsert |

## 课时

```yaml
lessons:
  - path: docs/01-setup.md     # 必需，相对仓库根目录
    title: 环境准备            # 可选，默认取首个一级标题或文件名
```

同步按 `path` 定位课时，写入标题、正文与顺序（数组下标 + 1）。正文按 Markdown 渲染，脚本与事件属性在渲染时移除。路径越出仓库时报「课时路径越界」，文件缺失时报「课时文件不存在」。

## 题库

```yaml
questions:
  - key: q1                 # 必需，课程内唯一，用于定位
    kind: single            # single / boolean / short
    stem: 哪个阶段先做？
    choices: [分析, 设计]    # 简答题可省略
    answer: 分析
    explanation: 分析回答 what。
    topic: SDLC
    slo: SLO1
    source: 2026 quiz
    lesson: docs/01-setup.md # 可选，按课时路径关联
```

题目按 `key` upsert；缺少 `key` 报「题目缺少 key」，引用的课时不存在报「题目引用的课时不存在」。

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
