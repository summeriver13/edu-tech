class Group < ApplicationRecord
  belongs_to :course
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :submissions, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :course_id }

  def contribution_percentages
    totals = course.contributions.where(user_id: member_ids).group(:user_id).sum(:hours)
    overall = totals.values.sum
    return {} if overall.zero?

    totals.transform_values { |hours| (hours / overall * 100).round(1) }
  end
end
