require "test_helper"

class CertificateTest < ActiveSupport::TestCase
  setup do
    @course = courses(:one)
    @user = users(:two)
  end

  test "is issued when every lesson is complete" do
    @course.lessons.first.lesson_completions.create!(user: @user)

    certificate = Certificate.issue_for(@user, @course)

    assert certificate.persisted?
    assert_equal @user, certificate.user
    assert_equal @course, certificate.course
    assert_match(/\ACS101-[A-Z0-9]{8}\z/, certificate.serial)
  end

  test "is not issued before the last lesson" do
    @course.lessons.create!(title: "第二课", position: 2)
    @course.lessons.first.lesson_completions.create!(user: @user)

    assert_nil Certificate.issue_for(@user, @course)
  end

  test "returns the existing record on a second call" do
    @course.lessons.first.lesson_completions.create!(user: @user)

    first = Certificate.issue_for(@user, @course)
    second = Certificate.issue_for(@user, @course)

    assert_equal first, second
    assert_equal 1, Certificate.count
  end

  test "needs at least one lesson" do
    other = Course.create!(title: "空课程", description: "无课时", course_number: "EMPTY1")

    assert_nil Certificate.issue_for(@user, other)
  end

  test "is unique per learner and course" do
    @course.lessons.first.lesson_completions.create!(user: @user)
    certificate = Certificate.issue_for(@user, @course)
    duplicate = Certificate.new(course: @course, user: @user, issued_at: Time.current)

    assert_not duplicate.valid?
    assert_equal certificate.serial, certificate.serial
  end
end
