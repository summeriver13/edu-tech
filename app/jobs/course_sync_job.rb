class CourseSyncJob < ApplicationJob
  queue_as :default

  def perform(course)
    course.update!(syncing_at: Time.current, sync_error: nil)
    result = CourseRepo.new(course).sync
    course.update!(syncing_at: nil, sync_error: result.success? ? nil : result.message)
  rescue StandardError => error
    course.update(syncing_at: nil, sync_error: "同步失败：#{error.message}")
  end
end
