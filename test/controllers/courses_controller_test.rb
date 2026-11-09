require "test_helper"

class CoursesControllerTest < ActionDispatch::IntegrationTest
  setup do
    log_in_as users(:one)
    @course = courses(:one)
  end

  test "should get index" do
    get courses_url
    assert_response :success
  end

  test "should search courses by keyword" do
    get courses_url(q: "Rails")
    assert_response :success
    assert_select "h3", text: courses(:two).title
    assert_select "h3", text: courses(:one).title, count: 0
  end

  test "should show empty state when nothing matches" do
    get courses_url(q: "no-such-course")
    assert_response :success
    assert_select "p", text: "没有匹配的课程。"
  end

  test "should paginate the course list" do
    10.times do |index|
      Course.create!(title: "Extra #{index}", description: "Extra course", course_number: "EX-#{index}")
    end

    get courses_url
    assert_select "h3", count: 9

    get courses_url(page: 2)
    assert_select "h3", count: 3
  end

  test "should get new" do
    get new_course_url
    assert_response :success
  end

  test "should create course" do
    assert_difference("Course.count") do
      post courses_url, params: { course: { course_number: "CS103", credit: @course.credit, description: @course.description, image_url: @course.image_url, title: @course.title } }
    end

    assert_redirected_to course_url(Course.last)
  end

  test "should show course" do
    get course_url(@course)
    assert_response :success
  end

  test "should get edit" do
    get edit_course_url(@course)
    assert_response :success
  end

  test "should update course" do
    patch course_url(@course), params: { course: { course_number: @course.course_number, credit: @course.credit, description: @course.description, image_url: @course.image_url, title: @course.title } }
    assert_redirected_to course_url(@course)
  end

  test "should destroy course" do
    assert_difference("Course.count", -1) do
      delete course_url(@course)
    end

    assert_redirected_to courses_url
  end
end
