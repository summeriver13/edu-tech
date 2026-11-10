class Lesson < ApplicationRecord
  belongs_to :course
  has_many :lesson_completions, dependent: :destroy
  has_many :questions, dependent: :nullify
  has_many :attempts, dependent: :nullify

  validates :title, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  scope :in_order, -> { order(:position, :id) }

  def best_score_for(user)
    return nil if user.nil?

    attempts.where(user: user).map(&:percent).max
  end

  def completed_by?(user)
    user.present? && lesson_completions.exists?(user_id: user.id)
  end
end
