require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:two)
    @assignment = assignments(:two)
    @student = users(:two)
  end

  test "student can submit" do
    log_in_as @student

    assert_difference("Submission.count") do
      post course_assignment_submission_url(@course, @assignment), params: { submission: { body: "我的答案" } }
    end

    assert_redirected_to course_assignment_url(@course, @assignment)
    assert_equal "我的答案", Submission.last.body
    assert_equal @student, Submission.last.user
  end

  test "student cannot submit twice" do
    log_in_as @student
    Submission.create!(assignment: @assignment, user: @student, body: "第一次")

    assert_no_difference("Submission.count") do
      post course_assignment_submission_url(@course, @assignment), params: { submission: { body: "第二次" } }
    end

    assert_redirected_to course_assignment_url(@course, @assignment)
    assert_equal "已经提交过了。", flash[:alert]
  end

  test "student can update the submission" do
    log_in_as @student
    submission = Submission.create!(assignment: @assignment, user: @student, body: "草稿")

    patch course_assignment_submission_url(@course, @assignment), params: { submission: { body: "终稿" } }

    assert_redirected_to course_assignment_url(@course, @assignment)
    assert_equal "终稿", submission.reload.body
  end

  test "an empty submission is rejected" do
    log_in_as @student

    assert_no_difference("Submission.count") do
      post course_assignment_submission_url(@course, @assignment), params: { submission: { body: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "teacher sees all submissions" do
    assignment = assignments(:one)
    Submission.create!(assignment: assignment, user: users(:one), body: "学生的答案")
    log_in_as users(:two)

    get course_assignment_url(courses(:one), assignment)

    assert_response :success
    assert_select "td", text: users(:one).name
    assert_select "td", text: "学生的答案"
  end

  test "requires login to submit" do
    post course_assignment_submission_url(@course, @assignment), params: { submission: { body: "x" } }
    assert_redirected_to new_session_url
  end
end
