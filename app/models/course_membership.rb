class CourseMembership < ApplicationRecord
  ROLES = %w[ teacher assistant student maintainer ].freeze
  MANAGE_ROLES = %w[ teacher assistant maintainer ].freeze

  belongs_to :course
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :course_id }

  def can_manage?
    MANAGE_ROLES.include?(role)
  end
end
