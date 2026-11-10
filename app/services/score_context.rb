class ScoreContext
  def initialize(course, users)
    @course = course
    @user_ids = users.map(&:id)
    @group_ids = load_groups
    @submissions = load_submissions
    @attempts = load_attempts
  end

  def submission(assessment, user)
    if assessment.group_work?
      group_id = @group_by_user[user.id]
      group_id ? @submissions_by_group[[ assessment.id, group_id ]] : nil
    else
      @submissions_by_user[[ assessment.id, user.id ]]
    end
  end

  def attempt_percents(assessment, user)
    @attempts.fetch([ assessment.id, user.id ], [])
  end

  def adjustment_factor(assessment, user)
    return 1 unless assessment.group_work?

    @adjustment_factors.fetch(user.id, 1)
  end

  private

  def load_groups
    rows = GroupMembership.joins(:group)
      .where(groups: { course_id: @course.id }, user_id: @user_ids)
      .pluck(:user_id, :group_id, :adjustment_factor)
    @group_by_user = {}
    @adjustment_factors = {}
    rows.each do |user_id, group_id, factor|
      @group_by_user[user_id] ||= group_id
      @adjustment_factors[user_id] ||= factor.to_f
    end
    @group_by_user.values.uniq
  end

  def load_submissions
    scope = Submission.where(assessment_id: @course.assessments.select(:id)).includes(:grade, :deliverable, :assessment)
    scope = if @group_ids.any?
      scope.where("user_id IN (:users) OR group_id IN (:groups)", users: @user_ids, groups: @group_ids)
    else
      scope.where(user_id: @user_ids)
    end
    @submissions_by_user = {}
    @submissions_by_group = {}
    scope.to_a.each do |submission|
      @submissions_by_user[[ submission.assessment_id, submission.user_id ]] = submission if submission.user_id
      @submissions_by_group[[ submission.assessment_id, submission.group_id ]] = submission if submission.group_id
    end
  end

  def load_attempts
    attempts = Attempt.where(assessment_id: @course.assessments.select(:id), user_id: @user_ids)
      .select(:assessment_id, :user_id, :score, :total)
    attempts.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |attempt, map|
      map[[ attempt.assessment_id, attempt.user_id ]] << attempt.percent
    end
  end
end
