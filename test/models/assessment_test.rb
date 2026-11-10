require "test_helper"

class AssessmentTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert assessments(:one).valid?
  end

  test "requires a title" do
    assessment = Assessment.new(course: courses(:one))
    assert_not assessment.valid?
    assert_includes assessment.errors[:title], "can't be blank"
  end

  test "rejects an unknown kind" do
    assessment = Assessment.new(course: courses(:one), title: "x", kind: "essay")
    assert_not assessment.valid?
    assert_includes assessment.errors[:kind], "is not included in the list"
  end

  test "rejects a weight outside 0 to 100" do
    assessment = Assessment.new(course: courses(:one), title: "x", weight: 120)
    assert_not assessment.valid?
    assert assessment.errors[:weight].any?
  end

  test "sums weights per course" do
    Assessment.create!(course: courses(:one), title: "考试", kind: "exam", weight: 60)
    assert_equal 100, courses(:one).assessment_weight_total
  end

  test "is removed with its course" do
    course = courses(:one)

    assert_difference("Assessment.count", -course.assessments.count) do
      course.destroy!
    end
  end
end
