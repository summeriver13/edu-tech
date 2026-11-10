class AttemptsController < ApplicationController
  before_action :require_login
  before_action :set_course
  before_action :require_course_member

  def show
    @attempt = scope.find(params[:id])
    @answers = @attempt.answers.includes(:question).order(:id)
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def scope
    course_manager?(@course) ? @course.attempts : @course.attempts.where(user: current_user)
  end
end
