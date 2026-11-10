require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert courses(:one).valid?
  end

  test "requires title, description and course_number" do
    course = Course.new
    assert_not course.valid?
    assert_includes course.errors[:title], "can't be blank"
    assert_includes course.errors[:description], "can't be blank"
    assert_includes course.errors[:course_number], "can't be blank"
  end

  test "requires a unique course_number" do
    course = Course.new(title: "Another", description: "Text", course_number: courses(:one).course_number)
    assert_not course.valid?
    assert_includes course.errors[:course_number], "has already been taken"
  end

  test "is managed by admins and course teachers" do
    assert courses(:one).manageable_by?(users(:one))
    assert courses(:one).manageable_by?(users(:two))
  end

  test "is not managed by students or anonymous users" do
    assert_not courses(:two).manageable_by?(users(:two))
    assert_not courses(:one).manageable_by?(nil)
  end

  test "rejects negative credit" do
    course = courses(:one)
    course.credit = -1
    assert_not course.valid?
  end
end
