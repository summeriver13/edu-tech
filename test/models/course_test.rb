require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert courses(:one).valid?
  end

  test "marks a hurdle failure as TF and maps totals to letters" do
    course = courses(:two)
    user = users(:two)

    assert_equal "TF", course.letter_grade(user)

    exam_submission = assessments(:exam).submissions.create!(user: user, body: "答案")
    exam_submission.create_grade!(score: 35)
    assessments(:lab).submissions.create!(user: user, body: "实验报告")
    report = assessments(:two).submissions.create!(user: user, body: "报告")
    report.create_grade!(score: 100)

    assert_equal "P", course.letter_grade(user)

    report.grade.update!(score: 80)
    assert_equal "F", course.letter_grade(user)
  end

  test "computes the week number from the term start" do
    course = courses(:one)
    course.update!(week1_start: Date.new(2026, 9, 14), time_zone: "Australia/Sydney")

    assert_equal 1, course.week_of(Time.utc(2026, 9, 16, 2, 0))
    assert_equal 2, course.week_of(Time.utc(2026, 9, 24, 0, 0))
    assert_nil course.week_of(Time.utc(2026, 9, 1))
  end

  test "renders times in the course zone" do
    course = courses(:one)
    course.update!(time_zone: "Australia/Sydney")

    assert_equal "2026-11-05 17:50", course.local_time(Time.utc(2026, 11, 5, 6, 50)).strftime("%Y-%m-%d %H:%M")
  end

  test "rejects an unknown time zone" do
    course = courses(:one)
    course.time_zone = "Mars/Olympus"

    assert_not course.valid?
    assert_includes course.errors[:time_zone], "不是有效时区"
  end
  test "requires title, description and course_number" do
    course = Course.new
    assert_not course.valid?
    assert_includes course.errors[:title], "can't be blank"
    assert_includes course.errors[:description], "can't be blank"
    assert_includes course.errors[:course_number], "can't be blank"
  end

  test "requires a unique course_number" do
    course = Course.new(title: "Another", description: "Text", course_number: courses(:one).course_number)
    assert_not course.valid?
    assert_includes course.errors[:course_number], "has already been taken"
  end

  test "is managed by admins and course teachers" do
    assert courses(:one).manageable_by?(users(:one))
    assert courses(:one).manageable_by?(users(:two))
  end

  test "is not managed by students or anonymous users" do
    assert_not courses(:two).manageable_by?(users(:two))
    assert_not courses(:one).manageable_by?(nil)
  end

  test "rejects a minimum attendance above 100" do
    course = courses(:one)
    course.min_attendance = 120

    assert_not course.valid?
  end

  test "reports whether term policies are set" do
    course = courses(:one)
    assert_not course.policies?

    course.census_at = Date.new(2026, 10, 5)
    assert course.policies?
  end

  test "rejects negative credit" do
    course = courses(:one)
    course.credit = -1
    assert_not course.valid?
  end
end
