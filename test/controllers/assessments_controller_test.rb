require "test_helper"

class AssessmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:one)
    @assessment = assessments(:one)
  end

  test "anyone can list assessments" do
    get course_assessments_url(@course)

    assert_response :success
    assert_select "a", text: /#{@assessment.title}/
  end

  test "the list shows weights and their total" do
    get course_assessments_url(@course)

    assert_select "td", text: "40%"
    assert_select "th", text: "合计"
  end

  test "the list warns when weights do not sum to 100" do
    @assessment.update!(weight: 40)
    get course_assessments_url(@course)

    assert_select ".alert-warning", text: /40%/
  end

  test "the list marks hurdles and pass fail assessments" do
    get course_assessments_url(courses(:two))

    assert_select ".badge", text: /门槛 ≥35%/
    assert_select ".badge", text: /门槛 须提交/
    assert_select ".badge", text: "及格制"
  end

  test "anyone can open an assessment" do
    get course_assessment_url(@course, @assessment)
    assert_response :success
  end

  test "course teacher can create an assessment" do
    log_in_as users(:two)

    assert_difference("Assessment.count") do
      post course_assessments_url(@course), params: { assessment: { title: "新作业", description: "描述", due_at: "2026-12-20T23:59" } }
    end

    assert_redirected_to course_assessment_url(@course, Assessment.last)
  end

  test "student cannot create an assessment" do
    log_in_as users(:two)

    assert_no_difference("Assessment.count") do
      post course_assessments_url(courses(:two)), params: { assessment: { title: "偷偷加" } }
    end

    assert_redirected_to root_url
    assert_equal "需要课程管理权限。", flash[:alert]
  end

  test "course teacher can update an assessment" do
    log_in_as users(:two)
    patch course_assessment_url(@course, @assessment), params: { assessment: { title: "改过的作业" } }

    assert_redirected_to course_assessment_url(@course, @assessment)
    assert_equal "改过的作业", @assessment.reload.title
  end

  test "course teacher can delete an assessment" do
    log_in_as users(:two)

    assert_difference("Assessment.count", -1) do
      delete course_assessment_url(@course, @assessment)
    end

    assert_redirected_to course_assessments_url(@course)
  end

  test "requires login to create an assessment" do
    get new_course_assessment_url(@course)
    assert_redirected_to new_session_url
  end
end
