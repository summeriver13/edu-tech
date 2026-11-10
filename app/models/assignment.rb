class Assignment < ApplicationRecord
  belongs_to :course
  has_many :submissions, dependent: :destroy

  validates :title, presence: true
end
