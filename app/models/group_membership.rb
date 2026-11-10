class GroupMembership < ApplicationRecord
  ROLES = %w[ manager member ].freeze

  belongs_to :group
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :group_id }
  validates :adjustment_factor, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2 }
end
