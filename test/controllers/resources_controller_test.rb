require "test_helper"

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    log_in_as users(:one)
    @course = courses(:one)
    @resource = resources(:one)
  end

  test "should get index" do
    get course_resources_url(@course)
    assert_response :success
  end

  test "should get new" do
    get new_course_resource_url(@course)
    assert_response :success
  end

  test "should create resource" do
    assert_difference("Resource.count") do
      post course_resources_url(@course), params: { resource: { description: "Weekly handout", name: "Handout", resource_type: "document", url: "https://example.com/handout.pdf" } }
    end

    assert_redirected_to course_resource_url(@course, Resource.last)
  end

  test "course teacher can create a resource" do
    log_in_as users(:two)

    assert_difference("Resource.count") do
      post course_resources_url(@course), params: { resource: { name: "Teacher note", resource_type: "document", url: "https://example.com/note.pdf" } }
    end

    assert_redirected_to course_resource_url(@course, Resource.last)
  end

  test "should create resource with a video" do
    assert_difference("Resource.count") do
      post course_resources_url(@course), params: { resource: { name: "Lecture video", resource_type: "video", video: fixture_file_upload("lecture.mp4", "video/mp4") } }
    end

    resource = Resource.last
    assert resource.video.present?
    assert File.exist?(resource.video.path)
    FileUtils.rm_f(resource.video.path)
  end

  test "should reject a resource without url and video" do
    assert_no_difference("Resource.count") do
      post course_resources_url(@course), params: { resource: { name: "Empty", resource_type: "document" } }
    end

    assert_response :unprocessable_entity
  end

  test "should remove the video file on destroy" do
    resource = @course.resources.create!(name: "Temp video", resource_type: "video", video: fixture_file_upload("lecture.mp4", "video/mp4"))
    path = resource.video.path

    delete course_resource_url(@course, resource)

    assert_not File.exist?(path)
  end

  test "should show resource" do
    get course_resource_url(@course, @resource)
    assert_response :success
  end

  test "should get edit" do
    get edit_course_resource_url(@course, @resource)
    assert_response :success
  end

  test "should update resource" do
    patch course_resource_url(@course, @resource), params: { resource: { name: "Renamed handout" } }
    assert_redirected_to course_resource_url(@course, @resource)
    assert_equal "Renamed handout", @resource.reload.name
  end

  test "should not update resource without name" do
    patch course_resource_url(@course, @resource), params: { resource: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy resource" do
    assert_difference("Resource.count", -1) do
      delete course_resource_url(@course, @resource)
    end

    assert_redirected_to course_resources_url(@course)
  end
end
