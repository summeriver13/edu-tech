require "test_helper"

class AttemptTest < ActiveSupport::TestCase
  test "computes a percentage" do
    attempt = Attempt.new(course: courses(:two), user: users(:two), taken_at: Time.current, score: 3, total: 4)
    assert_equal 75, attempt.percent
  end

  test "returns zero percent when nothing was asked" do
    attempt = Attempt.new(course: courses(:two), user: users(:two), taken_at: Time.current, score: 0, total: 0)
    assert_equal 0, attempt.percent
  end
end
