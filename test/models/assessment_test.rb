require "test_helper"

class AssessmentTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert assessments(:one).valid?
  end

  test "requires a title" do
    assessment = Assessment.new(course: courses(:one), kind: "assignment", weight: 10)
    assert_not assessment.valid?
  end

  test "accepts every kind, including presentation, essay and lab" do
    Assessment::KINDS.each do |kind|
      assessment = Assessment.new(course: courses(:one), title: "T", kind: kind, weight: 0)
      assert assessment.valid?, "#{kind} should be valid"
    end
  end

  test "rejects an unknown kind" do
    assessment = Assessment.new(course: courses(:one), title: "T", kind: "essay", weight: 0)
    assert assessment.valid?

    assessment.kind = "webinar"
    assert_not assessment.valid?
  end

  test "rejects a weight above 100" do
    assessment = assessments(:one)
    assessment.weight = 120
    assert_not assessment.valid?
  end

  test "sums the weights of a course" do
    assert_equal 60, courses(:two).assessment_weight_total
  end

  test "fails a hurdle when nothing was submitted" do
    assert assessments(:exam).hurdle_failed?(users(:two))
  end

  test "fails a hurdle when the minimum score is missed" do
    assessment = assessments(:exam)
    submission = assessment.submissions.create!(user: users(:two), body: "答案")
    submission.create_grade!(score: 34)

    assert assessment.hurdle_failed?(users(:two))

    submission.grade.update!(score: 35)
    assert_not assessment.hurdle_failed?(users(:two))
  end

  test "passes a hurdle that only asks for a submission" do
    assessment = assessments(:exam)
    assessment.update!(min_score: nil)
    assessment.submissions.create!(user: users(:two), body: "答案")

    assert_not assessment.hurdle_failed?(users(:two))
  end

  test "requires the hurdle flag for a minimum score" do
    assessment = Assessment.new(course: courses(:one), title: "T", kind: "exam", weight: 0, min_score: 30)
    assert_not assessment.valid?
    assert_includes assessment.errors[:min_score], "需要同时勾选门槛"
  end

  test "reports pass or fail for a pass fail assessment" do
    assessment = assessments(:two)
    assessment.update!(pass_fail: true)
    submission = assessment.submissions.create!(user: users(:two), body: "报告")
    submission.create_grade!(score: 49)

    assert_equal "未通过", assessment.outcome_for(users(:two))

    submission.grade.update!(score: 50)
    assert_equal "通过", assessment.outcome_for(users(:two))
  end
end
