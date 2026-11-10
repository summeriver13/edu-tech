module SubmissionSlots
  private

  def prepare_submission_slots
    @submissions = @assessment.submissions.includes(:user, :group, :grade, :deliverable).order(:created_at) if course_manager?(@course)
    return unless logged_in?

    @own_submissions = own_submissions
    @submissions_by_deliverable = @own_submissions.index_by(&:deliverable_id)
    @slots = @assessment.deliverables.any? ? @assessment.deliverables.to_a : [ nil ]
    @slot_rows = @slots.map { |deliverable| [ deliverable, slot_submission(deliverable) ] }
  end

  def own_submissions
    if @assessment.group_work?
      group = current_group_for_submission
      group ? @assessment.submissions.where(group_id: group.id) : @assessment.submissions.none
    else
      @assessment.submissions.where(user_id: current_user.id)
    end
  end

  def current_group_for_submission
    @assessment.group_work? ? @course.group_for(current_user) : nil
  end

  def slot_submission(deliverable)
    return @submission if @submission && @submission.deliverable_id == deliverable&.id
    return @submissions_by_deliverable[deliverable&.id] if @submissions_by_deliverable&.key?(deliverable&.id)

    @assessment.submissions.build(user: current_user, group: current_group_for_submission, deliverable: deliverable)
  end
end
