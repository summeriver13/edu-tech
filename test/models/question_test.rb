require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert questions(:single).valid?
  end

  test "compares answers case insensitively" do
    assert questions(:boolean).correct?(" TRUE ")
    assert_not questions(:boolean).correct?("false")
  end

  test "treats a blank response as wrong" do
    assert_not questions(:single).correct?("")
    assert_not questions(:single).correct?(nil)
  end

  test "rejects a lesson from another course" do
    question = questions(:single)
    question.lesson = lessons(:one)

    assert_not question.valid?
    assert_includes question.errors[:lesson], "必须属于同一课程"
  end

  test "rejects an unknown kind" do
    question = Question.new(course: courses(:two), stem: "x", answer: "y", kind: "essay")
    assert_not question.valid?
  end
end
