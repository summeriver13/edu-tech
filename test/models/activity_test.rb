require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert activities(:one).valid?
  end

  test "requires activity_type and start_time" do
    activity = Activity.new
    assert_not activity.valid?
    assert_includes activity.errors[:activity_type], "can't be blank"
    assert_includes activity.errors[:start_time], "can't be blank"
  end

  test "rejects end_time before start_time" do
    activity = activities(:one)
    activity.end_time = activity.start_time - 1.hour
    assert_not activity.valid?
    assert activity.errors[:end_time].any? { |message| message.start_with?("must be greater than or equal to") }
  end
end
