class Attempt < ApplicationRecord
  belongs_to :course
  belongs_to :user
  has_many :answers, dependent: :destroy

  validates :taken_at, presence: true
  validates :score, :total, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  def percent
    return 0 if total.zero?

    (score * 100.0 / total).round
  end
end
