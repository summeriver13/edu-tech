class AssessmentsController < ApplicationController
  include SubmissionSlots

  before_action :require_login, only: %i[ new create edit update destroy ]
  before_action :set_course
  before_action :require_course_manager, only: %i[ new create edit update destroy ]
  before_action :set_assessment, only: %i[ show edit update destroy ]

  def index
    @assessments = @course.assessments.order(:due_at)
  end

  def show
    prepare_submission_slots
  end

  def new
    @assessment = @course.assessments.build
  end

  def create
    @assessment = @course.assessments.build(assessment_params)
    if @assessment.save
      redirect_to course_assessment_path(@course, @assessment), notice: "评估已创建。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @assessment.update(assessment_params)
      redirect_to course_assessment_path(@course, @assessment), notice: "评估已更新。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assessment.destroy!
    redirect_to course_assessments_path(@course), notice: "评估已删除。", status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_assessment
    @assessment = @course.assessments.find(params[:id])
  end

  def assessment_params
    params.require(:assessment).permit(
      :title, :description, :due_at, :scope, :venue, :opens_at,
      :kind, :weight, :group_work, :group_min, :group_max,
      :hurdle, :min_score, :pass_fail, :sittings, :best_of,
      :word_limit, :word_limit_tolerance, :ai_policy, slos: []
    )
  end
end
