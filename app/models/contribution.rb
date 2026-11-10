class Contribution < ApplicationRecord
  STATUSES = %w[ planned done ].freeze

  belongs_to :course
  belongs_to :user

  validates :task, presence: true
  validates :on_date, presence: true
  validates :hours, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
end
