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
end
