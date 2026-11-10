# 课程模型补充：评估、小组、题库

依据本地真实课程仓库 `F:/Project-UOW/csit883`（UOW CSIT883，2026 S1）。该仓库把 Moodle 板块整体搬进 git，形成 110 个文件、25 MB 的教学资料库。它暴露出我们当前设计的三个缺口。

## 结论

| 缺口 | 现状 | 真实课程要求 |
|---|---|---|
| 评估结构 | `assignments` 只有标题、描述、截止时间 | 三项评估带权重 20 / 30 / 50、类型、个人或小组、SLO、范围、地点 |
| 小组协作 | `submissions` 一人一条 | 4–6 人一组、5 个交付物、贡献台账、个人分按贡献调整 |
| 练习与反馈 | 无题库、无成绩 | 每周 15–43 题、错题本、模考、复盘；评估成绩汇总 |

补充原则不变：**仓库存教学内容与评估骨架，数据库存小组、贡献、成绩、答题记录。**

## 边界

| 数据 | 存放 | 理由 |
|---|---|---|
| 评估项（权重、类型、截止、范围、SLO） | 课程仓库 `course.yml` | 需要 review 与版本化；学生可读 |
| 讲义、概念卡、题库题面 | 课程仓库 Markdown | 协作编辑，diff 可审 |
| 小组划分、贡献台账、学号、成绩、答题记录 | 数据库 | 隐私；需要关系查询与权限 |

## course.yml v2

新增 `term` 与 `assessments`，其余字段不变。

```yaml
course:
  title: System Analysis and Project Management
  course_number: CSIT883
  credit: 6
  description: 系统分析方法与 IT 项目管理

term:
  week1_start: 2026-08-31
  time_zone: Australia/Sydney
  weeks: 18

assessments:
  - key: quiz
    title: Quiz
    kind: quiz
    weight: 20
    group_work: false
    slos: [SLO1, SLO2, SLO3, SLO4]
    opens_at: 2026-11-05T16:10:00+11:00
    due_at: 2026-11-05T17:50:00+11:00
    venue: 南湖 N201
    scope: Lecture 1–6
  - key: group-project
    title: Group project
    kind: project
    weight: 30
    group_work: true
    slos: [SLO1, SLO2, SLO3, SLO4, SLO5, SLO6]
    due_at: 2026-12-13T23:59:00+11:00
    deliverables:
      - { name: proposal, due_at: 2026-10-13T23:59:00+11:00 }
      - { name: progress slides, due_at: 2026-11-30T23:59:00+11:00 }
      - { name: final slides }
      - { name: final report }
      - { name: deliverables }
  - key: final-exam
    title: Final exam
    kind: exam
    weight: 50
    group_work: false
    slos: [SLO1, SLO2, SLO3, SLO4]
    due_at: 2027-01-15T23:59:00+11:00

resources: []
activities: []
```

字段表：

| 字段 | 必需 | 说明 |
|---|---|---|
| `assessments[].key` | 是 | 课程内唯一，同步的定位键 |
| `kind` | 是 | `quiz` / `exam` / `project` / `assignment` |
| `weight` | 是 | 0–100，同一课程合计必须为 100 |
| `group_work` | 否 | 默认 `false` |
| `slos` | 否 | 字符串数组 |
| `opens_at` / `due_at` | 否 | 带时区偏移；库内统一存 UTC |
| `scope` / `venue` | 否 | 自由文本 |
| `deliverables` | 否 | 仅 `project` 使用，按名称 upsert |

## 数据库增量

```
assignments 改名为 assessments
  key            string   唯一索引 (course_id, key)
  kind           string   null: false, 默认 assignment
  weight         decimal  null: false, 默认 0
  group_work     boolean  null: false, 默认 false
  slos           json     默认 []
  scope, venue   string
  opens_at       datetime

groups               group_memberships        contributions
  course_id            group_id                 course_id
  name                 user_id                  user_id
  module               role (manager/member)    on_date
                       module                   task
                                                hours
                                                evidence_url
                                                status

submissions 新增 group_id (可空) —— 小组作业按组提交
grades      新增 submission_id, score, feedback, adjustment_factor(默认 1.0)
```

成绩计算：`assessment_score × weight / 100 × adjustment_factor`。个人分为各评估之和。

题库（第三刀）：

```
questions   course_id, topic, slo, kind, stem, choices(json), answer, explanation, source
attempts    user_id, course_id, taken_at, score
answers     attempt_id, question_id, response, correct
```

## 页面与权限

| 页面 | 路径 | 谁可见 |
|---|---|---|
| 评估表（权重合计校验） | `GET /courses/:id/assessments` | 全员 |
| 小组管理 | `GET /courses/:id/groups` | 课程管理者 |
| 贡献台账 | `GET /courses/:id/contributions` | 本课程成员；他人明细仅管理者 |
| 成绩册 | `GET /courses/:id/gradebook` | 管理者看全部；学生看自己 |
| 练习 | `GET /courses/:id/practice` | 本课程成员 |

写权限沿用 `require_course_manager`；`student` 只写自己的贡献与答题记录。

## 同步规则 v2

1. 事务内 upsert `assessments`，定位键 `(course_id, key)`。
2. 不同步 `groups`、`contributions`、`grades`、`answers`。
3. 校验收紧：`weight` 合计不等于 100 时拒绝同步，提示差值。
4. 删除策略不变：清单移除的记录留在库内。

## 周次与时区

真实仓库有两套周次口径（老师 `Week n` ≈ 本地 `W(n+2)`），且 Moodle 用悉尼时间、课表用北京时间。平台不猜：

- `courses.time_zone` 存 IANA 名称，默认 `Asia/Shanghai`。
- `courses.week1_start` 存日期；周次由 `(日期 - week1_start) / 7` 计算，不落库。
- `course.yml` 的时间必须带偏移量，导入后统一转 UTC，页面按 `time_zone` 渲染。

## 隐私

学号、英文姓名对照、贡献明细、成绩一律不入课程仓库。仓库只放评分规则与聚合口径。真实仓库已按此执行：`project/贡献记录.md` 只写作业署名，联系方式明确「不入库」。

## 分刀实施

| 刀 | 内容 | 验收 |
|:--:|---|---|
| 1 | `assessments` 扩展 + 评估表页面 + 同步 v2 | 用 CSIT883 的 `course.yml` 同步后，课程页显示 20 / 30 / 50，合计 100 |
| 2 | 小组、贡献台账、成绩调整 | 建 1 组 6 人，贡献合计 100%，个人分 = 组分 × 调整系数 |
| 3 | 题库、练习、错题本 | 导入 164 题（W1–W6），答错自动进错题本 |
| 4 | 周次、时区、课表视图 | 课表显示 `W3 lec` / `W4 tut`，与真实仓库日历一致 |

## 不做

- 不做 Moodle 克隆：论坛、公告、视频转码、LTI 对接。
- 不做在线监考与闭卷防作弊。
- 不做自动评分之外的主观题 AI 评分。

## 参考来源

- `F:/Project-UOW/csit883/README.md`：评估权重、课程信息、Moodle 板块映射
- `F:/Project-UOW/csit883/notes/学期日历.md`：周次双口径、时区
- `F:/Project-UOW/csit883/project/group-project.md`、`project/贡献记录.md`：小组与贡献
- `F:/Project-UOW/csit883/quiz/README.md`、`tutorials/README.md`：题库规模与题型
