class SubmissionsController < ApplicationController
  before_action :require_login
  before_action :set_assignment
  before_action :set_course

  def create
    if @assignment.submissions.exists?(user: current_user)
      return redirect_to course_assignment_path(@course, @assignment), alert: "已经提交过了。"
    end

    @submission = @assignment.submissions.build(submission_params.merge(user: current_user))
    if @submission.save
      redirect_to course_assignment_path(@course, @assignment), notice: "已提交。", status: :see_other
    else
      render "assignments/show", status: :unprocessable_entity
    end
  end

  def update
    @submission = @assignment.submissions.find_by!(user: current_user)
    if @submission.update(submission_params)
      redirect_to course_assignment_path(@course, @assignment), notice: "提交已更新。", status: :see_other
    else
      render "assignments/show", status: :unprocessable_entity
    end
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def set_course
    @course = @assignment.course
  end

  def submission_params
    params.require(:submission).permit(:body, :file)
  end
end
