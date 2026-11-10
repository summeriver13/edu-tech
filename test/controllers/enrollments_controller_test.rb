require "test_helper"

class EnrollmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:one)
  end

  test "a signed-in user joins an open course" do
    @course.update!(self_enrollment: true)
    student = User.create!(name: "Carol", password: "secret")
    log_in_as student

    assert_difference "CourseMembership.count", 1 do
      post course_enrollment_url(@course)
    end

    assert_redirected_to course_url(@course)
    assert_equal "已加入课程。", flash[:notice]
    follow_redirect!
    assert_select ".alert-success", text: "已加入课程。"
    assert @course.member?(student)
    assert_equal "student", @course.course_memberships.find_by(user: student).role
  end

  test "a closed course rejects enrollment" do
    student = User.create!(name: "Carol", password: "secret")
    log_in_as student

    assert_no_difference "CourseMembership.count" do
      post course_enrollment_url(@course)
    end

    assert_redirected_to course_url(@course)
    assert_equal "该课程未开放自选注册。", flash[:alert]
  end

  test "a guest cannot enroll" do
    @course.update!(self_enrollment: true)

    assert_no_difference "CourseMembership.count" do
      post course_enrollment_url(@course)
    end

    assert_redirected_to new_session_url
  end
end
