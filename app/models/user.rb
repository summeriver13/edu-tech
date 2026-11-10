class User < ApplicationRecord
  ROLES = %w[ admin member ].freeze

  has_secure_password

  has_many :course_memberships, dependent: :destroy
  has_many :courses, through: :course_memberships
  has_many :submissions, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end
end
