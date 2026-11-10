require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:two)
  end

  test "manager creates a question" do
    log_in_as users(:one)

    assert_difference("Question.count") do
      post course_questions_url(@course), params: {
        question: { kind: "short", stem: "什么是 SDLC？", answer: "系统开发生命周期", choices_text: "", topic: "SDLC" }
      }
    end

    assert_redirected_to course_questions_url(@course)
    assert_equal "系统开发生命周期", Question.order(:id).last.answer
  end

  test "a question may belong to a lesson" do
    lesson = @course.lessons.create!(title: "第一课", position: 1)
    log_in_as users(:one)

    post course_questions_url(@course), params: {
      question: { kind: "short", stem: "课时题？", answer: "是", lesson_id: lesson.id }
    }

    assert_equal lesson, Question.order(:id).last.lesson
  end

  test "choices are split by line" do
    log_in_as users(:one)
    post course_questions_url(@course), params: {
      question: { kind: "single", stem: "x", answer: "A", choices_text: "A\nB\n" }
    }

    assert_equal %w[ A B ], Question.order(:id).last.choices
  end

  test "paginates the question bank" do
    55.times { |i| @course.questions.create!(kind: "short", stem: "Q#{i}", answer: "A") }
    log_in_as users(:one)

    get course_questions_url(@course)
    assert_select "tbody tr", count: 50
    assert_select "a", text: "下一页"

    get course_questions_url(@course, page: 2)
    assert_response :success
    assert_select "tbody tr", count: 7
  end

  test "student cannot add a question" do
    log_in_as users(:two)

    assert_no_difference("Question.count") do
      post course_questions_url(@course), params: { question: { kind: "short", stem: "x", answer: "y" } }
    end

    assert_redirected_to root_url
    assert_equal "需要课程管理权限。", flash[:alert]
  end
end
