require "test_helper"

class GradesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:two)
    @assessment = assessments(:two)
    @submission = Submission.create!(assessment: @assessment, user: users(:two), body: "答案")
  end

  test "manager saves a score" do
    log_in_as users(:one)

    assert_difference("Grade.count") do
      patch course_assessment_submission_grade_url(@course, @assessment, @submission), params: { grade: { score: 88 } }
    end

    assert_redirected_to course_assessment_url(@course, @assessment)
    assert_equal 88, @submission.reload.grade.score
  end

  test "student cannot save a score" do
    log_in_as users(:two)

    assert_no_difference("Grade.count") do
      patch course_assessment_submission_grade_url(@course, @assessment, @submission), params: { grade: { score: 100 } }
    end

    assert_redirected_to root_url
    assert_equal "需要课程管理权限。", flash[:alert]
  end

  test "student sees an own weighted total" do
    Grade.create!(submission: @submission, score: 80)
    log_in_as users(:two)
    get course_grades_url(@course)

    assert_response :success
    assert_select "th", text: "总分"
    assert_select "td", text: /48\.0/
    assert_select "th", text: /TF/
    assert_select ".alert-danger", text: /期末考试/
  end

  test "manager sees every member" do
    Grade.create!(submission: @submission, score: 80)
    log_in_as users(:one)
    get course_grades_url(@course)

    assert_response :success
    assert_select "td", text: users(:two).name
  end

  test "rejects a score above 100" do
    log_in_as users(:one)
    patch course_assessment_submission_grade_url(@course, @assessment, @submission), params: { grade: { score: 120 } }

    assert_redirected_to course_assessment_url(@course, @assessment)
    assert flash[:alert].present?
  end
end
