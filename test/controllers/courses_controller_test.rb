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
      File.write(File.join(dir, "course.yml"), <<~YAML)
        course:
          title: 仓库标题
        resources:
          - name: 仓库讲义
            type: document
            url: https://example.com/handout.pdf
        activities:
          - type: 直播
            start: 2026-03-02T19:00:00+08:00
            location: 线上
        assessments:
          - key: quiz
            title: 仓库测验
            kind: quiz
            weight: 40
            slos: [SLO1]
          - key: exam
            title: 仓库考试
            kind: exam
            weight: 60
            due_at: 2026-12-13T23:59:00+11:00
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
      assert Activity.exists?(activity_type: "直播")
      assert_equal 100, @course.assessments.where(key: %w[ quiz exam ]).sum(:weight)
      assert_equal %w[ quiz exam ], @course.assessments.where(key: %w[ quiz exam ]).order(:weight).pluck(:kind)
    end
  ensure
    FileUtils.rm_rf(CourseRepo::REPO_ROOT.join(@course.course_number))
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
    FileUtils.rm_rf(CourseRepo::REPO_ROOT.join(@course.course_number))
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
    FileUtils.rm_rf(CourseRepo::REPO_ROOT.join(@course.course_number))
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
    FileUtils.rm_rf(CourseRepo::REPO_ROOT.join(@course.course_number))
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
