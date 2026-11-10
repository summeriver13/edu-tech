require "test_helper"

class CourseRepoTest < ActiveSupport::TestCase
  test "clones into a directory private to this test worker" do
    assert_includes CourseRepo::REPO_ROOT.to_s, Process.pid.to_s
    assert_not_includes CourseRepo::REPO_ROOT.to_s, "storage"
  end
end
