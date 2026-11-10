class Deliverable < ApplicationRecord
  belongs_to :assessment
  has_many :submissions, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :assessment_id }
end
