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

  test "attaches an attempt to a quiz assessment" do
    log_in_as @student
    post course_practice_url(@course), params: {
      assessment_id: assessments(:quiz).id,
      question_ids: [ questions(:single).id ],
      responses: { questions(:single).id.to_s => "分析" }
    }

    assert_equal assessments(:quiz), Attempt.order(:id).last.assessment
  end

  test "a lesson round only draws the questions of that lesson" do
    lesson = @course.lessons.create!(title: "第一课", position: 1)
    questions(:single).update!(lesson: lesson)
    log_in_as @student

    post course_practice_url(@course), params: {
      lesson_id: lesson.id,
      question_ids: [ questions(:single).id, questions(:boolean).id ],
      responses: { questions(:single).id.to_s => "分析", questions(:boolean).id.to_s => "true" }
    }

    attempt = Attempt.order(:id).last
    assert_equal lesson, attempt.lesson
    assert_equal 1, attempt.total
    assert_equal 1, attempt.score
    assert_equal "得分 100%，最好 100%。", flash[:notice]
  end

  test "the lesson keeps the best score across rounds" do
    lesson = @course.lessons.create!(title: "第一课", position: 1)
    questions(:single).update!(lesson: lesson)
    log_in_as @student

    post course_practice_url(@course), params: {
      lesson_id: lesson.id, question_ids: [ questions(:single).id ],
      responses: { questions(:single).id.to_s => "设计" }
    }
    post course_practice_url(@course), params: {
      lesson_id: lesson.id, question_ids: [ questions(:single).id ],
      responses: { questions(:single).id.to_s => "分析" }
    }

    assert_equal 100, lesson.reload.best_score_for(@student)
    assert_equal "得分 100%，最好 100%。", flash[:notice]
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
