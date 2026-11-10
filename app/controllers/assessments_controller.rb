class AssessmentsController < ApplicationController
  before_action :require_login, only: %i[ new create edit update destroy ]
  before_action :set_course
  before_action :require_course_manager, only: %i[ new create edit update destroy ]
  before_action :set_assessment, only: %i[ show edit update destroy ]

  def index
    @assessments = @course.assessments.order(:due_at)
  end

  def show
    @submission = own_submission
    @submissions = @assessment.submissions.includes(:user).order(:created_at) if course_manager?(@course)
  end

  def new
    @assessment = @course.assessments.build
  end

  def create
    @assessment = @course.assessments.build(assessment_params)
    if @assessment.save
      redirect_to course_assessment_path(@course, @assessment), notice: "作业已创建。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @assessment.update(assessment_params)
      redirect_to course_assessment_path(@course, @assessment), notice: "作业已更新。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assessment.destroy!
    redirect_to course_assessments_path(@course), notice: "作业已删除。", status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_assessment
    @assessment = @course.assessments.find(params[:id])
  end

  def own_submission
    return nil unless logged_in?

    @assessment.submissions.find_by(user: current_user) || @assessment.submissions.build(user: current_user)
  end

  def assessment_params
    params.require(:assessment).permit(:title, :description, :due_at)
  end
end
