require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "logs in with valid credentials" do
    post session_url, params: { name: users(:one).name, password: "secret" }
    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_match users(:one).name, response.body
  end

  test "rejects invalid credentials" do
    post session_url, params: { name: users(:one).name, password: "wrong" }
    assert_response :unprocessable_entity
    assert_match "用户名或密码错误", response.body
  end

  test "logs out" do
    log_in_as users(:one)
    delete session_url
    assert_redirected_to root_url
    follow_redirect!
    assert_select "a", text: "登录"
  end

  test "requires login for write actions" do
    delete course_url(courses(:one))
    assert_redirected_to new_session_url
  end

  test "member cannot write courses" do
    log_in_as users(:two)
    post courses_url, params: { course: { course_number: "M-1", title: "Member", description: "Nope" } }
    assert_redirected_to root_url
    assert_equal "需要管理员权限。", flash[:alert]
  end

  test "member cannot manage users" do
    log_in_as users(:two)
    get users_url
    assert_redirected_to root_url
  end

  test "returns to the stored page after login" do
    get new_course_url
    assert_redirected_to new_session_url
    post session_url, params: { name: users(:one).name, password: "secret" }
    assert_redirected_to new_course_url
  end
end
