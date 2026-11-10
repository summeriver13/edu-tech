class SubmissionsController < ApplicationController
  include SubmissionSlots

  before_action :require_login
  before_action :set_assessment
  before_action :set_course

  def create
    if @assessment.group_work? && current_group_for_submission.nil?
      return redirect_to course_assessment_path(@course, @assessment), alert: "尚未分组，请联系教师。"
    end

    if own_submissions.exists?(deliverable_id: submission_params[:deliverable_id].presence)
      return redirect_to course_assessment_path(@course, @assessment), alert: "已经提交过了。"
    end

    @submission = @assessment.submissions.build(submission_params.merge(user: current_user, group: current_group_for_submission))
    if @submission.save
      redirect_to course_assessment_path(@course, @assessment), notice: "已提交。", status: :see_other
    else
      prepare_submission_slots
      render "assessments/show", status: :unprocessable_entity
    end
  end

  def update
    @submission = own_submissions.find(params[:id])
    if @submission.update(submission_params)
      redirect_to course_assessment_path(@course, @assessment), notice: "提交已更新。", status: :see_other
    else
      prepare_submission_slots
      render "assessments/show", status: :unprocessable_entity
    end
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id])
  end

  def set_course
    @course = @assessment.course
  end

  def submission_params
    params.require(:submission).permit(:body, :file, :deliverable_id)
  end
end
