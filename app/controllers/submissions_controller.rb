class SubmissionsController < ApplicationController
  before_action :require_login
  before_action :set_assessment
  before_action :set_course

  def create
    if @assessment.submissions.exists?(user: current_user)
      return redirect_to course_assessment_path(@course, @assessment), alert: "已经提交过了。"
    end

    @submission = @assessment.submissions.build(submission_params.merge(user: current_user))
    if @submission.save
      redirect_to course_assessment_path(@course, @assessment), notice: "已提交。", status: :see_other
    else
      render "assessments/show", status: :unprocessable_entity
    end
  end

  def update
    @submission = @assessment.submissions.find_by!(user: current_user)
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

  def submission_params
    params.require(:submission).permit(:body, :file)
  end
end
