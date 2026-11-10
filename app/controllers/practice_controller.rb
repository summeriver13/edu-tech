class PracticeController < ApplicationController
  QUESTION_LIMIT = 10

  before_action :require_login
  before_action :set_course
  before_action :require_course_member

  def show
    @questions = @course.questions.order(Arel.sql("RANDOM()")).limit(QUESTION_LIMIT)
  end

  def create
    questions = @course.questions.where(id: Array(params[:question_ids])).to_a
    return redirect_to course_practice_path(@course), alert: "没有可作答的题目。" if questions.empty?

    responses = params.fetch(:responses, {}).to_unsafe_h
    attempt = @course.attempts.new(user: current_user, taken_at: Time.current, total: questions.size)
    attempt.score = questions.count { |question| question.correct?(responses[question.id.to_s]) }

    Attempt.transaction do
      attempt.save!
      questions.each do |question|
        response = responses[question.id.to_s]
        attempt.answers.create!(question: question, response: response, correct: question.correct?(response))
      end
    end

    redirect_to course_attempt_path(@course, attempt), notice: "得分 #{attempt.percent}%。"
  end

  def mistakes
    wrong_ids = Answer.joins(:attempt)
      .where(attempts: { course_id: @course.id, user_id: current_user.id }, correct: false)
      .select(:question_id)
    @questions = @course.questions.where(id: wrong_ids).order(:topic, :id)
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end
end
