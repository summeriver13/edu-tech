class LessonsController < ApplicationController
  PUBLIC_MAX_AGE = 120

  before_action :set_course
  before_action :set_lesson

  def show
    @completed = @lesson.completed_by?(logged_in? ? current_user : nil)
    @best_score = @lesson.best_score_for(logged_in? ? current_user : nil)
    @previous = @course.lessons.where("position < ?", @lesson.position).last
    @next = @course.lessons.where("position > ?", @lesson.position).first
    fresh_when(
      etag: [ @lesson, @lesson.questions.maximum(:updated_at), current_user&.id, @completed, @best_score ],
      last_modified: @lesson.updated_at,
      public: !logged_in?
    )
    response.cache_control[:max_age] = PUBLIC_MAX_AGE unless logged_in?
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_lesson
    @lesson = @course.lessons.find(params[:id])
  end
end
