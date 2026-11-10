class Grade < ApplicationRecord
  belongs_to :submission

  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
