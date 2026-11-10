require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_registration_url
    assert_response :success
  end

  test "creates a member account and logs in" do
    assert_difference("User.count") do
      post registration_url, params: { user: { name: "newbie", password: "secret", password_confirmation: "secret", role: "admin" } }
    end

    user = User.find_by(name: "newbie")
    assert_equal "member", user.role
    assert_redirected_to root_url
    follow_redirect!
    assert_match "newbie", response.body
  end

  test "rejects mismatched confirmation" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { name: "broken", password: "secret", password_confirmation: "other" } }
    end

    assert_response :unprocessable_entity
  end

  test "rejects a duplicate name" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { name: users(:one).name, password: "secret", password_confirmation: "secret" } }
    end

    assert_response :unprocessable_entity
  end
end
