require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    assert users(:one).valid?
    assert users(:two).valid?
  end

  test "knows admins" do
    assert users(:one).admin?
    assert_not users(:two).admin?
  end

  test "rejects unknown roles" do
    user = users(:two)
    user.role = "superuser"
    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "requires a unique name" do
    user = User.new(name: users(:one).name, password: "secret", password_confirmation: "secret")
    assert_not user.valid?
    assert_includes user.errors[:name], "has already been taken"
  end
end
