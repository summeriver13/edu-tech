require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = courses(:two)
  end

  test "members can list groups" do
    log_in_as users(:two)
    get course_groups_url(@course)

    assert_response :success
    assert_select "td", text: /第一组/
  end

  test "manager creates a group" do
    log_in_as users(:one)

    assert_difference("Group.count") do
      post course_groups_url(@course), params: { group: { name: "第二组" } }
    end

    assert_redirected_to course_groups_url(@course)
  end

  test "student cannot create a group" do
    log_in_as users(:two)

    assert_no_difference("Group.count") do
      post course_groups_url(@course), params: { group: { name: "第二组" } }
    end

    assert_redirected_to root_url
    assert_equal "需要课程管理权限。", flash[:alert]
  end

  test "manager adds and removes a member" do
    log_in_as users(:one)

    assert_difference("GroupMembership.count") do
      post course_group_group_memberships_url(@course, groups(:two)), params: { user_name: "Alice", role: "manager", module_name: "M4" }
    end
    membership = GroupMembership.order(:id).last
    assert_equal "manager", membership.role
    assert_equal "M4", membership.module_name

    assert_difference("GroupMembership.count", -1) do
      delete course_group_group_membership_url(@course, groups(:two), membership)
    end
    assert_redirected_to course_groups_url(@course)
  end

  test "reports an unknown user name" do
    log_in_as users(:one)

    assert_no_difference("GroupMembership.count") do
      post course_group_group_memberships_url(@course, groups(:two)), params: { user_name: "ghost", role: "member" }
    end

    assert_equal "找不到用户。", flash[:alert]
  end

  test "manager deletes a group" do
    log_in_as users(:one)

    assert_difference("Group.count", -1) do
      delete course_group_url(@course, groups(:two))
    end

    assert_redirected_to course_groups_url(@course)
  end

  test "requires login" do
    get course_groups_url(@course)
    assert_redirected_to new_session_url
  end
end
