class AssignmentsController < ApplicationController
  before_action :require_login, only: %i[ new create edit update destroy ]
  before_action :set_course
  before_action :require_course_manager, only: %i[ new create edit update destroy ]
  before_action :set_assignment, only: %i[ show edit update destroy ]

  def index
    @assignments = @course.assignments.order(:due_at)
  end

  def show
    @submission = own_submission
    @submissions = @assignment.submissions.includes(:user).order(:created_at) if course_manager?(@course)
  end

  def new
    @assignment = @course.assignments.build
  end

  def create
    @assignment = @course.assignments.build(assignment_params)
    if @assignment.save
      redirect_to course_assignment_path(@course, @assignment), notice: "作业已创建。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @assignment.update(assignment_params)
      redirect_to course_assignment_path(@course, @assignment), notice: "作业已更新。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assignment.destroy!
    redirect_to course_assignments_path(@course), notice: "作业已删除。", status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_assignment
    @assignment = @course.assignments.find(params[:id])
  end

  def own_submission
    return nil unless logged_in?

    @assignment.submissions.find_by(user: current_user) || @assignment.submissions.build(user: current_user)
  end

  def assignment_params
    params.require(:assignment).permit(:title, :description, :due_at)
  end
end
