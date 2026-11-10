class GradesController < ApplicationController
  before_action :require_login
  before_action :set_course
  before_action :require_course_member
  before_action :require_course_manager, only: %i[ update ]
  before_action :set_submission, only: %i[ update ]

  def index
    @assessments = @course.assessments.order(:due_at)
    @rows = if course_manager?(@course)
              @course.members.order(:name).map { |user| [ user, @course.grade_for(user) ] }
            else
              [ [ current_user, @course.grade_for(current_user) ] ]
            end
  end

  def update
    grade = @submission.grade || @submission.build_grade
    if grade.update(grade_params)
      redirect_to course_assessment_path(@course, @submission.assessment), notice: "成绩已保存。"
    else
      redirect_to course_assessment_path(@course, @submission.assessment), alert: grade.errors.full_messages.to_sentence
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_submission
    @submission = @course.assessments.find(params[:assessment_id]).submissions.find(params[:submission_id])
  end

  def grade_params
    params.require(:grade).permit(:score, :feedback)
  end
end
