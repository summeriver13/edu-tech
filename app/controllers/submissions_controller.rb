class SubmissionsController < ApplicationController
  before_action :require_login
  before_action :set_assessment
  before_action :set_course

  def create
    if @assessment.group_work? && current_group.nil?
      return redirect_to course_assessment_path(@course, @assessment), alert: "尚未分组，请联系教师。"
    end

    if @assessment.submission_for(current_user)
      return redirect_to course_assessment_path(@course, @assessment), alert: "已经提交过了。"
    end

    @submission = @assessment.submissions.build(submission_params.merge(user: current_user, group: current_group))
    if @submission.save
      redirect_to course_assessment_path(@course, @assessment), notice: "已提交。", status: :see_other
    else
      render "assessments/show", status: :unprocessable_entity
    end
  end

  def update
    @submission = own_submission || raise(ActiveRecord::RecordNotFound)
    if @submission.update(submission_params)
      redirect_to course_assessment_path(@course, @assessment), notice: "提交已更新。", status: :see_other
    else
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

  def current_group
    @assessment.group_work? ? @course.group_for(current_user) : nil
  end

  def own_submission
    @assessment.submission_for(current_user)
  end

  def submission_params
    params.require(:submission).permit(:body, :file)
  end
end
