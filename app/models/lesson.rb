class Lesson < ApplicationRecord
  belongs_to :course
  has_many :lesson_completions, dependent: :destroy

  validates :title, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  scope :in_order, -> { order(:position, :id) }

  def completed_by?(user)
    user.present? && lesson_completions.exists?(user_id: user.id)
  end
end
