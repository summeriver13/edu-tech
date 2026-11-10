require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:one)
    @teacher = users(:two)
  end

  test "course teacher can list members" do
    log_in_as @teacher
    get course_memberships_url(@course)

    assert_response :success
    assert_select "td", text: @teacher.name
  end

  test "course teacher can add a member" do
    log_in_as @teacher
    student = User.create!(name: "Cara", password: "secret", password_confirmation: "secret")

    assert_difference("CourseMembership.count") do
      post course_memberships_url(@course), params: { user_name: student.name, role: "student" }
    end

    assert_redirected_to course_memberships_url(@course)
    assert_equal "student", CourseMembership.last.role
  end

  test "reports an unknown user name" do
    log_in_as @teacher

    assert_no_difference("CourseMembership.count") do
      post course_memberships_url(@course), params: { user_name: "nobody", role: "student" }
    end

    assert_redirected_to course_memberships_url(@course)
    assert_equal "找不到用户。", flash[:alert]
  end

  test "rejects a duplicate membership" do
    log_in_as @teacher

    assert_no_difference("CourseMembership.count") do
      post course_memberships_url(@course), params: { user_name: @teacher.name, role: "assistant" }
    end

    assert_response :unprocessable_entity
  end

  test "course teacher can remove a member" do
    log_in_as @teacher
    membership = course_memberships(:teacher)

    assert_difference("CourseMembership.count", -1) do
      delete course_membership_url(@course, membership)
    end

    assert_redirected_to course_memberships_url(@course)
  end

  test "student cannot manage members" do
    log_in_as @teacher

    get course_memberships_url(courses(:two))

    assert_redirected_to root_url
    assert_equal "需要课程管理权限。", flash[:alert]
  end

  test "requires login" do
    get course_memberships_url(@course)
    assert_redirected_to new_session_url
  end
end
