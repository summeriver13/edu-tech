require "test_helper"

class AssignmentTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert assignments(:one).valid?
  end

  test "requires a title" do
    assignment = Assignment.new(course: courses(:one))
    assert_not assignment.valid?
    assert_includes assignment.errors[:title], "can't be blank"
  end

  test "is removed with its course" do
    course = courses(:one)

    assert_difference("Assignment.count", -course.assignments.count) do
      course.destroy!
    end
  end
end
