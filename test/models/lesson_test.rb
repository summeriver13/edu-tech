require "test_helper"

class LessonTest < ActiveSupport::TestCase
  test "requires a title" do
    lesson = lessons(:one)
    lesson.title = ""

    assert_not lesson.valid?
  end

  test "orders lessons by position" do
    course = courses(:one)
    second = course.lessons.create!(title: "第二课", position: 2)
    first = course.lessons.create!(title: "第三课", position: 3)

    assert_equal [ lessons(:one), second, first ], course.lessons.in_order.to_a
  end

  test "reports completion for one user only" do
    lesson = lessons(:one)
    assert_not lesson.completed_by?(users(:two))

    lesson.lesson_completions.create!(user: users(:two))
    assert lesson.completed_by?(users(:two))
    assert_not lesson.completed_by?(users(:one))
  end

  test "counts progress across the course" do
    course = courses(:one)
    course.lessons.create!(title: "第二课", position: 2)
    course.lessons.first.lesson_completions.create!(user: users(:two))

    assert_equal [ 1, 2 ], course.lesson_progress_for(users(:two))
    assert_equal [ 0, 2 ], course.lesson_progress_for(nil)
  end
end
