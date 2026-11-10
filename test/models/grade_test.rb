require "test_helper"

class GradeTest < ActiveSupport::TestCase
  setup do
    @submission = Submission.create!(assessment: assessments(:two), user: users(:two), body: "答案")
  end

  test "rejects a score above 100" do
    grade = Grade.new(submission: @submission, score: 120)

    assert_not grade.valid?
    assert grade.errors[:score].any?
  end

  test "accepts a score within range" do
    assert Grade.new(submission: @submission, score: 88).valid?
  end
end
