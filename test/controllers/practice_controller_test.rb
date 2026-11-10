require "test_helper"

class PracticeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:two)
    @student = users(:two)
  end

  test "member starts a practice round" do
    log_in_as @student
    get course_practice_url(@course)

    assert_response :success
    assert_select "form"
  end

  test "member submits answers and gets a result" do
    log_in_as @student

    assert_difference [ "Attempt.count", "Answer.count" ], 1 do
      post course_practice_url(@course), params: {
        question_ids: [ questions(:single).id ],
        responses: { questions(:single).id.to_s => "分析" }
      }
    end

    attempt = Attempt.order(:id).last
    assert_redirected_to course_attempt_url(@course, attempt)
    assert_equal 1, attempt.score
    assert attempt.answers.first.correct?
  end

  test "wrong answers land in the mistake book" do
    log_in_as @student
    post course_practice_url(@course), params: {
      question_ids: [ questions(:single).id ],
      responses: { questions(:single).id.to_s => "设计" }
    }

    get course_practice_mistakes_url(@course)

    assert_response :success
    assert_select ".card .fw-semibold", text: questions(:single).stem
  end

  test "non members are refused" do
    outsider = User.create!(name: "outsider", role: "member", password: "secret")
    log_in_as outsider
    get course_practice_url(@course)
    assert_redirected_to root_url
    assert_equal "需要课程成员身份。", flash[:alert]
  end
end
