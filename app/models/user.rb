class User < ApplicationRecord
  ROLES = %w[ admin member ].freeze

  has_secure_password

  has_many :course_memberships, dependent: :destroy
  has_many :courses, through: :course_memberships
  has_many :submissions, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :contributions, dependent: :destroy
  has_many :attempts, dependent: :destroy
  has_many :lesson_completions, dependent: :destroy
  has_many :certificates, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end
end
