require "test_helper"
require "tmpdir"

class CoursesControllerTest < ActionDispatch::IntegrationTest
  setup do
    log_in_as users(:one)
    @course = courses(:one)
  end

  test "should get index" do
    get courses_url
    assert_response :success
  end

  test "should search courses by keyword" do
    get courses_url(q: "Rails")
    assert_response :success
    assert_select "h3", text: courses(:two).title
    assert_select "h3", text: courses(:one).title, count: 0
  end

  test "should show empty state when nothing matches" do
    get courses_url(q: "no-such-course")
    assert_response :success
    assert_select "p", text: "没有匹配的课程。"
  end

  test "should paginate the course list" do
    10.times do |index|
      Course.create!(title: "Extra #{index}", description: "Extra course", course_number: "EX-#{index}")
    end

    get courses_url
    assert_select "h3", count: 9

    get courses_url(page: 2)
    assert_select "h3", count: 3
  end

  test "should get new" do
    get new_course_url
    assert_response :success
  end

  test "should create course" do
    assert_difference("Course.count") do
      post courses_url, params: { course: { course_number: "CS103", credit: @course.credit, description: @course.description, cover: fixture_file_upload("cover.png", "image/png"), title: @course.title } }
    end

    assert_redirected_to course_url(Course.last)
  end

  test "should show course" do
    get course_url(@course)
    assert_response :success
  end

  test "should list resources and activities on the course page" do
    get course_url(@course)
    assert_response :success
    assert_select "a", text: /#{resources(:one).name}/
    assert_select "a", text: /#{activities(:one).activity_type}/
  end

  test "shows the completion record link on the course page" do
    @course.lessons.first.lesson_completions.create!(user: users(:two))
    certificate = Certificate.issue_for(users(:two), @course)
    log_in_as users(:two)

    get course_url(@course)

    assert_select "a", text: "查看完成记录", href: certificate_path(certificate.serial)
  end

  test "shows the term policies on the course page" do
    @course.update!(census_at: Date.new(2026, 10, 5), min_attendance: 80, late_penalty_percent: 5, late_penalty_max_days: 4)
    get course_url(@course)

    assert_response :success
    assert_select ".fw-semibold", text: "学期政策"
    assert_select "li", text: /Census 日期 2026-10-05/
    assert_select "li", text: /最低出勤率 80%/
    assert_select "li", text: /迟交每天扣 5 分/
  end

  test "should get edit" do
    get edit_course_url(@course)
    assert_response :success
  end

  test "should update course" do
    patch course_url(@course), params: { course: { course_number: @course.course_number, credit: @course.credit, description: @course.description, cover: fixture_file_upload("cover.png", "image/png"), title: @course.title } }
    assert_redirected_to course_url(@course)
  end

  test "should destroy course" do
    assert_difference("Course.count", -1) do
      delete course_url(@course)
    end

    assert_redirected_to courses_url
  end

  test "course teacher can update the course" do
    log_in_as users(:two)
    patch course_url(@course), params: { course: { title: "Teacher edit", description: @course.description, course_number: @course.course_number } }

    assert_redirected_to course_url(@course)
    assert_equal "Teacher edit", @course.reload.title
  end

  test "student cannot edit another course" do
    log_in_as users(:two)
    get edit_course_url(courses(:two))

    assert_redirected_to root_url
    assert_equal "需要课程管理权限。", flash[:alert]
  end

  test "sync imports the course repo manifest" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "docs"))
      File.write(File.join(dir, "docs", "01.md"), "# 第一课\n\n正文。\n")
      File.write(File.join(dir, "course.yml"), <<~YAML)
        course:
          title: 仓库标题
        lessons:
          - path: docs/01.md
        questions:
          - key: q1
            kind: single
            stem: 哪个先？
            choices: [分析, 设计]
            answer: 分析
            lesson: docs/01.md
        resources:
          - name: 仓库讲义
            type: document
            url: https://example.com/handout.pdf
        activities:
          - type: 直播
            start: 2026-03-02T19:00:00+08:00
            location: 线上
        term:
          week1_start: 2026-08-31
          time_zone: Australia/Sydney
          weeks: 18
          late_penalty:
            percent_per_day: 5
            max_days: 4
          census_at: 2026-10-05
          min_attendance: 80
        assessments:
          - key: quiz
            title: 仓库测验
            kind: quiz
            weight: 40
            sittings: 13
            best_of: 10
            slos: [SLO1]
          - key: exam
            title: 仓库考试
            kind: exam
            weight: 60
            hurdle: true
            min_score: 35
            word_limit: 2000
            word_limit_tolerance: 10
            ai_policy: not_permitted
            group_min: 1
            group_max: 5
            due_at: 2026-12-13T23:59:00+11:00
            deliverables:
              - name: proposal
                due_at: 2026-10-13T23:59:00+11:00
              - name: final report
      YAML
      git_commit(dir)
      @course.update!(repo_url: dir)
      log_in_as users(:two)

      assert_difference ["Resource.count", "Activity.count"] do
        assert_difference "Assessment.count", 2 do
          post sync_course_url(@course)
        end
      end

      assert_redirected_to course_url(@course)
      assert_match "已同步", flash[:notice]
      assert @course.reload.commit_sha.present?
      assert_equal "仓库标题", @course.title
      assert Resource.exists?(name: "仓库讲义")
      assert_equal Date.new(2026, 8, 31), @course.reload.week1_start
      assert_equal "Australia/Sydney", @course.time_zone
      assert Activity.exists?(activity_type: "直播")
      assert_equal 100, @course.assessments.where(key: %w[ quiz exam ]).sum(:weight)
      assert_equal %w[ quiz exam ], @course.assessments.where(key: %w[ quiz exam ]).order(:weight).pluck(:kind)
      synced_quiz = @course.assessments.find_by!(key: "quiz")
      assert_equal 13, synced_quiz.sittings
      assert_equal 10, synced_quiz.best_of
      synced_exam = @course.assessments.find_by!(key: "exam")
      assert synced_exam.hurdle?
      assert_equal 35, synced_exam.min_score.to_i
      assert_equal 2000, synced_exam.word_limit
      assert_equal [ 1800, 2200 ], synced_exam.word_range
      assert_equal [ "final report", "proposal" ], synced_exam.deliverables.pluck(:name).sort
      assert_equal 5, @course.late_penalty_percent.to_i
      assert_equal 4, @course.late_penalty_max_days
      assert_equal Date.new(2026, 10, 5), @course.census_at
      assert_equal 80, @course.min_attendance
      assert_equal "not_permitted", synced_exam.ai_policy
      lesson = @course.lessons.first
      assert_equal "第一课", lesson.title
      assert_equal 1, lesson.position
      assert_includes lesson.body, "正文"
      synced_question = Question.find_by!(key: "q1")
      assert_equal lesson, synced_question.lesson
      assert_equal %w[ 分析 设计 ], synced_question.choices
    end
  ensure
    FileUtils.rm_rf(CourseRepo.repo_root.join(@course.course_number))
  end

  test "sync rejects weights that do not sum to 100" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "course.yml"), <<~YAML)
        assessments:
          - key: quiz
            title: 测验
            kind: quiz
            weight: 90
      YAML
      git_commit(dir)
      @course.update!(repo_url: dir)
      log_in_as users(:two)

      assert_no_difference ["Assessment.count"] do
        post sync_course_url(@course)
      end

      assert_redirected_to course_url(@course)
      assert_match "权重合计必须为 100", flash[:alert]
      assert_nil @course.reload.commit_sha
    end
  ensure
    FileUtils.rm_rf(CourseRepo.repo_root.join(@course.course_number))
  end

  test "sync reclones when the repository address changes" do
    Dir.mktmpdir do |first|
      Dir.mktmpdir do |second|
        File.write(File.join(first, "course.yml"), "course:\n  title: 一号\n")
        git_commit(first)
        File.write(File.join(second, "course.yml"), "course:\n  title: 二号\n")
        git_commit(second)
        log_in_as users(:two)

        @course.update!(repo_url: first)
        post sync_course_url(@course)
        assert_equal "一号", @course.reload.title

        @course.update!(repo_url: second)
        post sync_course_url(@course)
        assert_equal "二号", @course.reload.title
      end
    end
  ensure
    FileUtils.rm_rf(CourseRepo.repo_root.join(@course.course_number))
  end

  test "sync reports a missing manifest" do
    Dir.mktmpdir do |dir|
      git_commit(dir)
      @course.update!(repo_url: dir)
      log_in_as users(:two)

      post sync_course_url(@course)

      assert_redirected_to course_url(@course)
      assert_match "同步失败", flash[:alert]
      assert_nil @course.reload.commit_sha
    end
  ensure
    FileUtils.rm_rf(CourseRepo.repo_root.join(@course.course_number))
  end

  test "sync rejects a question without a key" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "course.yml"), <<~YAML)
        questions:
          - stem: 无键题目
            kind: short
            answer: 答案
      YAML
      git_commit(dir)
      @course.update!(repo_url: dir)
      log_in_as users(:two)

      assert_no_difference "Question.count" do
        post sync_course_url(@course)
      end

      assert_match "题目缺少 key", flash[:alert]
    end
  ensure
    FileUtils.rm_rf(CourseRepo.repo_root.join(@course.course_number))
  end

  test "preview lists changes without writing them" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "docs"))
      File.write(File.join(dir, "docs", "02.md"), "# 新课时\n\n正文。\n")
      File.write(File.join(dir, "course.yml"), <<~YAML)
        course:
          title: 预览标题
        lessons:
          - path: docs/02.md
        questions:
          - key: q1
            kind: short
            stem: 题干？
            answer: 答案
            lesson: docs/02.md
      YAML
      git_commit(dir)
      @course.update!(repo_url: dir)
      log_in_as users(:two)

      assert_no_difference [ "Lesson.count", "Question.count" ] do
        get preview_course_url(@course)
      end

      assert_response :success
      assert_select ".badge", text: "新增", count: 2
      assert_select ".badge", text: "更新", count: 1
      assert_select "li", text: /课程信息/
      assert_select "li", text: %r{课时 docs/02.md}
      assert_select "li", text: /题目 q1/
    end
  ensure
    FileUtils.rm_rf(CourseRepo.repo_root.join(@course.course_number))
  end

  test "preview reports no changes after a sync" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "course.yml"), "course:\n  title: 一致标题\n")
      git_commit(dir)
      @course.update!(repo_url: dir)
      log_in_as users(:two)
      post sync_course_url(@course)

      get preview_course_url(@course)

      assert_response :success
      assert_select "p", text: /没有变化/
    end
  ensure
    FileUtils.rm_rf(CourseRepo.repo_root.join(@course.course_number))
  end

  test "student cannot preview a course sync" do
    log_in_as users(:two)

    get preview_course_url(courses(:two))

    assert_redirected_to root_url
    assert_equal "需要课程管理权限。", flash[:alert]
  end

  test "sync rejects a lesson outside the repository" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "course.yml"), <<~YAML)
        lessons:
          - path: ../outside.md
      YAML
      File.write(File.join(dir, "..", "outside.md"), "# 越界\n")
      git_commit(dir)
      @course.update!(repo_url: dir)
      log_in_as users(:two)

      assert_no_difference "Lesson.count" do
        post sync_course_url(@course)
      end

      assert_match "课时路径越界", flash[:alert]
    end
  ensure
    FileUtils.rm_rf(CourseRepo.repo_root.join(@course.course_number))
  end

  test "student cannot sync a course" do
    log_in_as users(:two)
    post sync_course_url(courses(:two))

    assert_redirected_to root_url
    assert_equal "需要课程管理权限。", flash[:alert]
  end

  private

  def git_commit(dir)
    File.write(File.join(dir, ".keep"), "")
    system("git", "-C", dir, "init", "--quiet", exception: true)
    system("git", "-C", dir, "add", ".", exception: true)
    system("git", "-C", dir, "-c", "user.email=test@example.com", "-c", "user.name=Test", "commit", "--quiet", "-m", "init", exception: true)
  end
end
