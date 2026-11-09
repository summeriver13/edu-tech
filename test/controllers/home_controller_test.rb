require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows recent courses" do
    get root_url
    assert_response :success
    assert_select "h3", text: courses(:one).title
    assert_select "h3", text: courses(:two).title
  end

  test "shows recent activities" do
    get root_url
    assert_response :success
    assert_select "strong", text: activities(:one).activity_type
  end
end
