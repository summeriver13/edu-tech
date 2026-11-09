require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:one)
    @activity = activities(:one)
  end

  test "should get index" do
    get course_activities_url(@course)
    assert_response :success
  end

  test "should get new" do
    get new_course_activity_url(@course)
    assert_response :success
  end

  test "should create activity" do
    assert_difference("Activity.count") do
      post course_activities_url(@course), params: { activity: { activity_type: "lecture", start_time: Time.current, end_time: 1.hour.from_now, location: "Room 101", description: "Intro lecture" } }
    end

    assert_redirected_to course_activity_url(@course, Activity.last)
  end

  test "should show activity" do
    get course_activity_url(@course, @activity)
    assert_response :success
  end

  test "should get edit" do
    get edit_course_activity_url(@course, @activity)
    assert_response :success
  end

  test "should update activity" do
    patch course_activity_url(@course, @activity), params: { activity: { location: "Room 202" } }
    assert_redirected_to course_activity_url(@course, @activity)
    assert_equal "Room 202", @activity.reload.location
  end

  test "should not update activity without start_time" do
    patch course_activity_url(@course, @activity), params: { activity: { start_time: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy activity" do
    assert_difference("Activity.count", -1) do
      delete course_activity_url(@course, @activity)
    end

    assert_redirected_to course_activities_url(@course)
  end
end
