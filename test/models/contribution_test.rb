require "test_helper"

class ContributionTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert contributions(:two).valid?
  end

  test "requires a task and a date" do
    contribution = Contribution.new(course: courses(:two), user: users(:two), hours: 1, status: "done")

    assert_not contribution.valid?
    assert_includes contribution.errors[:task], "can't be blank"
    assert_includes contribution.errors[:on_date], "can't be blank"
  end

  test "rejects negative hours and unknown status" do
    contribution = Contribution.new(course: courses(:two), user: users(:two), on_date: Date.current, task: "x", hours: -1, status: "maybe")

    assert_not contribution.valid?
    assert contribution.errors[:hours].any?
    assert contribution.errors[:status].any?
  end
end
