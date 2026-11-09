class Activity < ApplicationRecord
  belongs_to :course

  validates :activity_type, :start_time, presence: true
  validates :end_time, comparison: { greater_than_or_equal_to: :start_time }, allow_nil: true
end
