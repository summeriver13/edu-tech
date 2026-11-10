require "test_helper"

class CourseMembershipTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert course_memberships(:teacher).valid?
  end

  test "requires a known role" do
    membership = CourseMembership.new(course: courses(:one), user: users(:one), role: "owner")
    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"
  end

  test "allows one membership per course and user" do
    membership = CourseMembership.new(course: courses(:one), user: users(:two), role: "student")
    assert_not membership.valid?
    assert_includes membership.errors[:user_id], "has already been taken"
  end

  test "knows which roles manage a course" do
    assert course_memberships(:teacher).can_manage?
    assert_not course_memberships(:student).can_manage?
  end
end
