require "test_helper"
require "tmpdir"

class CourseSyncJobTest < ActiveJob::TestCase
  setup do
    @course = courses(:two)
  end

  test "imports the manifest and clears the syncing flag" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "course.yml"), "course:\n  title: 后台标题\n")
      git_init(dir)
      @course.update!(repo_url: dir, syncing_at: Time.current)

      CourseSyncJob.perform_now(@course)

      assert_nil @course.reload.syncing_at
      assert_nil @course.sync_error
      assert_equal "后台标题", @course.title
    end
  ensure
    FileUtils.rm_rf(CourseRepo.repo_root.join(@course.course_number))
  end

  test "records a failure message" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "notes.txt"), "no manifest")
      git_init(dir)
      @course.update!(repo_url: dir, syncing_at: Time.current)

      CourseSyncJob.perform_now(@course)

      assert_nil @course.reload.syncing_at
      assert_match "仓库缺少 course.yml", @course.sync_error
    end
  ensure
    FileUtils.rm_rf(CourseRepo.repo_root.join(@course.course_number))
  end
end
