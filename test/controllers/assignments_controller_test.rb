require "test_helper"

class AssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:one)
    @assignment = assignments(:one)
  end

  test "anyone can list assignments" do
    get course_assignments_url(@course)

    assert_response :success
    assert_select "a", text: /#{@assignment.title}/
  end

  test "anyone can open an assignment" do
    get course_assignment_url(@course, @assignment)
    assert_response :success
  end

  test "course teacher can create an assignment" do
    log_in_as users(:two)

    assert_difference("Assignment.count") do
      post course_assignments_url(@course), params: { assignment: { title: "新作业", description: "描述", due_at: "2026-12-20T23:59" } }
    end

    assert_redirected_to course_assignment_url(@course, Assignment.last)
  end

  test "student cannot create an assignment" do
    log_in_as users(:two)

    assert_no_difference("Assignment.count") do
      post course_assignments_url(courses(:two)), params: { assignment: { title: "偷偷加" } }
    end

    assert_redirected_to root_url
    assert_equal "需要课程管理权限。", flash[:alert]
  end

  test "course teacher can update an assignment" do
    log_in_as users(:two)
    patch course_assignment_url(@course, @assignment), params: { assignment: { title: "改过的作业" } }

    assert_redirected_to course_assignment_url(@course, @assignment)
    assert_equal "改过的作业", @assignment.reload.title
  end

  test "course teacher can delete an assignment" do
    log_in_as users(:two)

    assert_difference("Assignment.count", -1) do
      delete course_assignment_url(@course, @assignment)
    end

    assert_redirected_to course_assignments_url(@course)
  end

  test "requires login to create an assignment" do
    get new_course_assignment_url(@course)
    assert_redirected_to new_session_url
  end
end
