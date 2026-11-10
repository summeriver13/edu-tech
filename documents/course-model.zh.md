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

## 四门课对照（CSIT881 / CSIT882 / CSIT985）

刀 1–4 只对齐 CSIT883。补齐另外三门后，还缺六个机制。

| 课程 | 评估结构 | 我们缺什么 |
|---|---|---|
| CSIT881 Programming and Data Structures | 编程作业 5 次个人 50%，期末 50%；期末须 ≥30% 否则 TF；tutorial 出勤须 ≥80%；迟交每日扣 5%，超 4 天不给分；作业禁止 GenAI | 通过门槛、出勤门槛、迟交规则、AI 政策 |
| CSIT882 Data Management Systems | Quiz 40%（13 次选 10 次计分，每次 4%）+ 期末 60%；3 次作业权重 0 但必须先交；Lab 记 S/U | 最好 N 次计分、零权重前置条件、及格制 |
| CSIT985 Strategic Network Design | Quiz 10% + Presentation 10%（小组）+ Essay 10%（2000 词 ±10%）+ 项目 30%（小组，报告 10,000 词 + 视频 10 分钟）+ 期末 40%；期末须 ≥35% 否则 TF | 展示与论文类型、字数限制、小组人数区间、视频交付物 |
| CSIT883 System Analysis and Project Management | Quiz 20% + 项目 30% + 期末 50% | 已覆盖 |

### 新增机制

| 机制 | 真实证据 | 落地 |
|---|---|---|
| 通过门槛（hurdle） | 881 期末 ≥30%、985 期末 ≥35%，否则记 TF | `assessments.hurdle` + `min_score`；成绩册显示 TF |
| 零权重前置 | 882 三次作业 0%，但不交就不能参加期末 | `weight: 0` + `hurdle: true` + `min_score: null`：只需提交 |
| 及格制 | 882 Lab 记 Satisfactory / Unsatisfactory | `assessments.pass_fail`，成绩只记通过与否 |
| 最好 N 次 | 882 13 次 quiz 选 10 次计分 | `assessments.best_of` + `attempts.assessment_id`，取最高的 N 次 |
| 字数限制 | 985 essay 2000 词 ±10%，报告 10,000 词 | `assessments.word_limit` + `word_limit_tolerance`，只提示不拦交 |
| 小组人数 | 985 1–5 人，883 4–6 人 | `assessments.group_min` / `group_max`，建组时校验 |
| 迟交扣分 | 881 每日 5%，超 4 天不给分 | `term.late_penalty`，成绩计算时按天扣 |
| 出勤门槛 | 881 tut ≥80%，否则可能 TF | `term.min_attendance`，先只显示；无考勤表 |
| AI 政策 | 881 禁止；883 允许并需声明 | `assessments.ai_policy`，只显示 |
| 成绩等级 | UOW 记 HD / D / C / P / F，门槛失败记 TF | `Course#letter_grade`，按 85 / 75 / 65 / 50 分档 |

### course.yml v3 增量

`kind` 扩为 `quiz` / `exam` / `project` / `assignment` / `presentation` / `essay` / `lab`。

```yaml
term:
  week1_start: 2026-08-31
  time_zone: Australia/Sydney
  weeks: 18
  census_at: 2026-10-05
  min_attendance: 80
  late_penalty: { percent_per_day: 5, max_days: 4 }

assessments:
  - key: exam
    title: Final exam
    kind: exam
    weight: 40
    hurdle: true
    min_score: 35
    ai_policy: not_permitted
  - key: quizzes
    title: Weekly quizzes
    kind: quiz
    weight: 40
    sittings: 13
    best_of: 10
  - key: lab
    title: Lab
    kind: lab
    weight: 0
    pass_fail: true
  - key: essay
    title: Essay
    kind: essay
    weight: 10
    word_limit: 2000
    word_limit_tolerance: 10
  - key: presentation
    title: Presentation
    kind: presentation
    weight: 10
    group_work: true
    group_min: 1
    group_max: 5
    opens_at: 2026-10-26T00:00:00+11:00
    due_at: 2026-11-23T23:59:00+11:00
```

### 数据库增量 v3

```
courses    新增 census_at (date), min_attendance (integer), late_penalty_percent (decimal), late_penalty_max_days (integer)
assessments 新增 hurdle (boolean, 默认 false), min_score (decimal, 可空), pass_fail (boolean, 默认 false),
             best_of (integer, 可空), sittings (integer, 可空),
             word_limit (integer, 可空), word_limit_tolerance (integer, 默认 10),
             group_min (integer, 可空), group_max (integer, 可空), ai_policy (string)
attempts   新增 assessment_id (可空外键)；为空表示自主练习
deliverables 新表：assessment_id, name, due_at；submissions 附件按交付物命名
```

### 成绩与门槛规则

```
assessment_score = 单项得分（best_of 时取最高 N 次的平均）
adjusted         = clamp(assessment_score × adjustment_factor, 0, 100)
late_penalty     = min(迟交天数 × 5%, 上限)
weighted         = (adjusted − late_penalty) × weight / 100
total            = Σ weighted
letter_grade     = TF 如果任一 hurdle 失败；否则按 85 / 75 / 65 / 50 分档
hurdle 失败条件   = min_score 存在且 adjusted < min_score；或 min_score 为空且未提交
```

## 隐私

学号、英文姓名对照、贡献明细、成绩一律不入课程仓库。仓库只放评分规则与聚合口径。真实仓库已按此执行：`project/贡献记录.md` 只写作业署名，联系方式明确「不入库」。

## 分刀实施

| 刀 | 内容 | 验收 |
|:--:|---|---|
| 1 | `assessments` 扩展 + 评估表页面 + 同步 v2 | 用 CSIT883 的 `course.yml` 同步后，课程页显示 20 / 30 / 50，合计 100 |
| 2 | 小组、贡献台账、成绩调整 | 建 1 组 6 人，贡献合计 100%，个人分 = 组分 × 调整系数 |
| 3 | 题库、练习、错题本 | 导入 164 题（W1–W6），答错自动进错题本 |
| 4 | 周次、时区、课表视图 | 课表显示 `W3 lec` / `W4 tut`，与真实仓库日历一致 |
| 5 | 评估类型与门槛：`kind` 加 `presentation` / `essay` / `lab`，加 `hurdle` / `min_score` / `pass_fail`，成绩册显示等级与 TF | 985 期末 35% 门槛：低于 35 分显示 TF |
| 6 | 多次测验：`attempts` 关联评估，`best_of` 取最高 N 次 | 882 建 13 次 quiz，只算最高 10 次 |
| 7 | 交付物与提交规则：`deliverables` 落库，字数提示、小组人数校验、迟交扣分 | 985 五项交付物齐全；essay 超 ±10% 给提示 |
| 8 | 学期政策：census 日期、出勤门槛、AI 政策 | 课程页显示学期政策区块 |

## 不做

- 不做 Moodle 克隆：论坛、公告、视频转码、LTI 对接。
- 不做在线监考与闭卷防作弊。
- 不做自动评分之外的主观题 AI 评分。
- 不在平台内运行学生代码自动判题：CSIT881 的 `test_labNN.py` 由学生在本地跑。平台执行不可信代码需要沙箱与资源配额，超出当前范围。

## 参考来源

- `F:/Project-UOW/csit883/README.md`：评估权重、课程信息、Moodle 板块映射
- `F:/Project-UOW/csit883/notes/学期日历.md`：周次双口径、时区
- `F:/Project-UOW/csit883/project/group-project.md`、`project/贡献记录.md`：小组与贡献
- `F:/Project-UOW/csit883/quiz/README.md`、`tutorials/README.md`：题库规模与题型
- `F:/Project-UOW/csit881/README.md`「评估安排」「必须记住的规则」：50/50 权重、30% 期末门槛、出勤 80%、迟交 5%/天
- `F:/Project-UOW/csit882/README.md`「评估安排」：Quiz 40%（13 选 10）、作业 0% 前置、Lab S/U、期末 60%
- `F:/Project-UOW/csit985/README.md`「评估安排」：五项权重、期末 35% 门槛 TF、essay 字数、小组 1–5 人
