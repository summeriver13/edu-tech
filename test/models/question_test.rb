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

  test "rejects an unknown kind" do
    question = Question.new(course: courses(:two), stem: "x", answer: "y", kind: "essay")
    assert_not question.valid?
  end
end
