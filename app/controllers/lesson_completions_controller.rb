class LessonCompletionsController < ApplicationController
  before_action :require_login
  before_action :set_course
  before_action :set_lesson
  before_action :require_course_member

  def create
    @lesson.lesson_completions.find_or_create_by(user: current_user)
    redirect_to course_lesson_path(@course, @lesson), notice: "已标记完成。"
  end

  def destroy
    @lesson.lesson_completions.where(user: current_user).destroy_all
    redirect_to course_lesson_path(@course, @lesson), notice: "已取消完成。", status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_lesson
    @lesson = @course.lessons.find(params[:lesson_id])
  end
end
