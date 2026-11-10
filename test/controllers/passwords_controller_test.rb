require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    get edit_password_url
    assert_redirected_to new_session_url
  end

  test "should get edit when logged in" do
    log_in_as users(:two)
    get edit_password_url
    assert_response :success
  end

  test "updates the password with the current password" do
    log_in_as users(:two)
    patch password_url, params: { current_password: "secret", password: "newsecret", password_confirmation: "newsecret" }

    assert_redirected_to root_url
    assert users(:two).reload.authenticate("newsecret")
  end

  test "rejects a wrong current password" do
    log_in_as users(:two)
    patch password_url, params: { current_password: "wrong", password: "newsecret", password_confirmation: "newsecret" }

    assert_response :unprocessable_entity
    assert_match "当前密码不正确。", response.body
    assert users(:two).reload.authenticate("secret")
  end
end
