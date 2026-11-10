class Question < ApplicationRecord
  KINDS = %w[ single boolean short ].freeze

  belongs_to :course
  has_many :answers, dependent: :destroy

  validates :stem, presence: true
  validates :answer, presence: true
  validates :kind, inclusion: { in: KINDS }

  def correct?(response)
    given = normalize(response)
    return false if given.empty?

    given == normalize(answer)
  end

  private

  def normalize(value)
    value.to_s.strip.downcase
  end
end
