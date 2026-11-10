class LessonCompletion < ApplicationRecord
  belongs_to :lesson
  belongs_to :user

  validates :user_id, uniqueness: { scope: :lesson_id }
  before_validation -> { self.completed_at ||= Time.current }
end
