class QuestionsController < ApplicationController
  before_action :require_login
  before_action :set_course
  before_action :require_course_manager

  def index
    @questions = @course.questions.order(:topic, :id)
  end

  def new
    @question = @course.questions.build(kind: "single")
  end

  def create
    @question = @course.questions.build(question_params)
    @question.choices = choices_from(params.dig(:question, :choices_text))
    if @question.save
      redirect_to course_questions_path(@course), notice: "题目已添加。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @course.questions.find(params[:id]).destroy!
    redirect_to course_questions_path(@course), notice: "题目已删除。", status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def choices_from(text)
    text.to_s.split("\n").map(&:strip).reject(&:empty?)
  end

  def question_params
    params.require(:question).permit(:kind, :topic, :slo, :stem, :answer, :explanation, :source)
  end
end
