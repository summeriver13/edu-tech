require "test_helper"

class ResourceTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert resources(:one).valid?
  end

  test "requires name and resource_type" do
    resource = Resource.new
    assert_not resource.valid?
    assert_includes resource.errors[:name], "can't be blank"
    assert_includes resource.errors[:resource_type], "can't be blank"
  end

  test "requires a url or a video" do
    resource = Resource.new(course: courses(:one), name: "Empty", resource_type: "document")
    assert_not resource.valid?
    assert_includes resource.errors[:base], "请提供链接或视频文件"
  end

  test "is valid with a video" do
    resource = Resource.new(course: courses(:one), name: "Lecture", resource_type: "video")
    File.open(Rails.root.join("test/fixtures/files/lecture.mp4")) do |file|
      resource.video = file
      assert resource.valid?
    end
  end
end
