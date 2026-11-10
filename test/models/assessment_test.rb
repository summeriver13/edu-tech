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

  test "scores a quiz from the best attempts" do
    assessment = assessments(:quiz)
    assessment.update!(sittings: 3, best_of: 2)
    user = users(:two)
    [ 10, 5, 0 ].each do |score|
      assessment.attempts.create!(course: courses(:two), user: user, taken_at: Time.current, score: score, total: 10)
    end

    assert_equal 75.0, assessment.attempt_score_for(user)
  end

  test "uses attempt scores when no grade exists" do
    assessment = assessments(:quiz)
    assessment.update!(weight: 40)
    assessment.attempts.create!(course: courses(:two), user: users(:two), taken_at: Time.current, score: 8, total: 10)

    assert_equal 80.0, assessment.raw_score_for(users(:two))
    assert_equal 32.0, assessment.weighted_score_for(users(:two))
  end

  test "computes the allowed word range" do
    assessment = assessments(:two)
    assessment.update!(word_limit: 2000, word_limit_tolerance: 10)

    assert_equal [ 1800, 2200 ], assessment.word_range
  end

  test "penalises a late submission and stops at the day cap" do
    course = courses(:two)
    course.update!(late_penalty_percent: 5, late_penalty_max_days: 4)
    assessment = assessments(:two)
    submission = assessment.submissions.create!(user: users(:two), body: "迟到")
    submission.create_grade!(score: 100)
    submission.update_column(:updated_at, assessment.due_at + 2.days)

    assert_equal 10, assessment.late_penalty_for(submission.reload)
    assert_equal 90.0, assessment.penalized_score_for(users(:two))

    submission.update_column(:updated_at, assessment.due_at + 5.days)
    assert_equal 100, assessment.late_penalty_for(submission.reload)
    assert_equal 0.0, assessment.penalized_score_for(users(:two))
  end

  test "rejects best_of above the planned sittings" do
    assessment = assessments(:quiz)
    assessment.best_of = 14

    assert_not assessment.valid?
    assert_includes assessment.errors[:best_of], "不能超过次数"
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
