require "test_helper"

class ContributionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:two)
  end

  test "member records an own contribution" do
    log_in_as users(:two)

    assert_difference("Contribution.count") do
      post course_contributions_url(@course), params: { contribution: { on_date: "2026-10-12", task: "合稿", hours: 2.5, status: "done" } }
    end

    assert_equal users(:two), Contribution.order(:id).last.user
    assert_redirected_to course_contributions_url(@course)
  end

  test "member sees only own rows" do
    Contribution.create!(course: @course, user: users(:one), on_date: Date.current, task: "组长的记录", hours: 1)
    log_in_as users(:two)
    get course_contributions_url(@course)

    assert_response :success
    assert_select "td", text: "写提案"
    assert_select "td", text: "组长的记录", count: 0
  end

  test "manager sees every row" do
    Contribution.create!(course: @course, user: users(:one), on_date: Date.current, task: "组长的记录", hours: 1)
    log_in_as users(:one)
    get course_contributions_url(@course)

    assert_select "td", text: "写提案"
    assert_select "td", text: "组长的记录"
  end

  test "rejects invalid hours" do
    log_in_as users(:two)

    assert_no_difference("Contribution.count") do
      post course_contributions_url(@course), params: { contribution: { on_date: "2026-10-12", task: "x", hours: -1, status: "done" } }
    end

    assert_redirected_to course_contributions_url(@course)
    assert flash[:alert].present?
  end

  test "requires login" do
    get course_contributions_url(@course)
    assert_redirected_to new_session_url
  end
end
