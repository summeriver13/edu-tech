class EnrollmentsController < ApplicationController
  before_action :require_login
  before_action :set_course

  def create
    unless @course.self_enrollment?
      redirect_to course_path(@course), alert: "该课程未开放自选注册。"
      return
    end

    @course.enroll(current_user)
    redirect_to course_path(@course), notice: "已加入课程。"
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end
end
