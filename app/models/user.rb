class User < ApplicationRecord
  ROLES = %w[ admin member ].freeze

  has_secure_password

  validates :name, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end
end
