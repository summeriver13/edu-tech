require "test_helper"

class CertificatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:one)
    @user = users(:two)
    @course.lessons.first.lesson_completions.create!(user: @user)
    @certificate = Certificate.issue_for(@user, @course)
  end

  test "anyone can verify a record by serial" do
    get certificate_url(@certificate.serial)

    assert_response :success
    assert_select "h1", text: @course.title
    assert_select "code", text: @certificate.serial
    assert_select "p", text: /Bob 已完成/
  end

  test "an unknown serial is not found" do
    get certificate_url("NOPE-00000000")

    assert_response :not_found
  end
end
