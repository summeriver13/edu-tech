class Assessment < ApplicationRecord
  KINDS = %w[ quiz exam project assignment ].freeze
  KIND_LABELS = {
    "quiz" => "测验",
    "exam" => "考试",
    "project" => "项目",
    "assignment" => "作业"
  }.freeze

  belongs_to :course
  has_many :submissions, dependent: :destroy

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
