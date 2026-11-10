require "test_helper"

class LessonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:one)
    @lesson = lessons(:one)
  end

  test "anyone can read a lesson" do
    get course_lesson_url(@course, @lesson)

    assert_response :success
    assert_select "h1", text: "第一课"
    assert_select ".lesson-body h1", text: "第一课"
  end

  test "revalidates a public lesson with an etag" do
    get course_lesson_url(@course, @lesson)
    etag = response.headers["ETag"]
    assert etag.present?
    assert_includes response.headers["Cache-Control"], "public"

    get course_lesson_url(@course, @lesson), headers: { "If-None-Match" => etag }

    assert_response :not_modified
  end

  test "does not reuse an anonymous etag for a member" do
    get course_lesson_url(@course, @lesson)
    etag = response.headers["ETag"]
    log_in_as users(:two)
    get course_lesson_url(@course, @lesson)

    get course_lesson_url(@course, @lesson), headers: { "If-None-Match" => etag }

    assert_response :success
    assert_select ".btn", text: "标记完成"
    assert_not_includes response.headers["Cache-Control"], "public"
  end

  test "renders the precomputed html when present" do
    @lesson.update!(body: "旧正文", body_html: "<p>预渲染正文</p>")

    get course_lesson_url(@course, @lesson)

    assert_select ".lesson-body p", text: "预渲染正文"
    assert_select ".lesson-body p", text: "旧正文", count: 0
  end

  test "shows the lesson quiz with the best score" do
    @lesson.questions.create!(course: @course, kind: "short", stem: "题干？", answer: "答案")
    @lesson.attempts.create!(course: @course, user: users(:two), score: 1, total: 1, taken_at: Time.current)
    log_in_as users(:two)

    get course_lesson_url(@course, @lesson)

    assert_select ".fw-semibold", text: "本课测验"
    assert_select ".small", text: /最好 100%/
    assert_select "a", text: "再测一次"
  end

  test "a member marks a lesson complete" do
    log_in_as users(:two)

    assert_difference "LessonCompletion.count", 1 do
      post course_lesson_completion_url(@course, @lesson)
    end

    assert_redirected_to course_lesson_url(@course, @lesson)
    assert_equal "已标记完成，完成记录已生成。", flash[:notice]
    assert @lesson.completed_by?(users(:two))
    assert Certificate.exists?(course: @course, user: users(:two))
  end

  test "the completion record is issued only once" do
    log_in_as users(:two)
    post course_lesson_completion_url(@course, @lesson)
    delete course_lesson_completion_url(@course, @lesson)

    assert_no_difference "Certificate.count" do
      post course_lesson_completion_url(@course, @lesson)
    end
  end

  test "a member cancels completion" do
    log_in_as users(:two)
    @lesson.lesson_completions.create!(user: users(:two))

    assert_difference "LessonCompletion.count", -1 do
      delete course_lesson_completion_url(@course, @lesson)
    end

    assert_redirected_to course_lesson_url(@course, @lesson)
  end

  test "a non-member cannot mark a lesson complete" do
    outsider = User.create!(name: "Carol", password: "secret")
    log_in_as outsider

    assert_no_difference "LessonCompletion.count" do
      post course_lesson_completion_url(@course, @lesson)
    end

    assert_redirected_to root_url
    assert_equal "需要课程成员身份。", flash[:alert]
  end

  test "links to the neighbouring lessons" do
    second = @course.lessons.create!(title: "第二课", position: 2)
    get course_lesson_url(@course, @lesson)

    assert_select "a", text: /第二课/
    get course_lesson_url(@course, second)
    assert_select "a", text: /第一课/
  end
end
