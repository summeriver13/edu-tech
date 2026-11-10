require "test_helper"

class GroupTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert groups(:two).valid?
  end

  test "requires a unique name per course" do
    duplicate = Group.new(course: courses(:two), name: groups(:two).name)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "computes contribution percentages from hours" do
    GroupMembership.create!(group: groups(:two), user: users(:one), role: "member")
    Contribution.create!(course: courses(:two), user: users(:one), on_date: Date.current, task: "评审", hours: 4)
    percentages = groups(:two).contribution_percentages

    assert_equal({ users(:two).id => 50.0, users(:one).id => 50.0 }, percentages)
  end
end
