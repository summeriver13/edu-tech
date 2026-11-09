class ActivitiesController < ApplicationController
  before_action :require_login, only: %i[ new edit create update destroy ]
  before_action :set_course
  before_action :set_activity, only: %i[ show edit update destroy ]

  def index
    @activities = @course.activities.order(start_time: :desc)
  end

  def show
  end

  def new
    @activity = @course.activities.build
  end

  def edit
  end

  def create
    @activity = @course.activities.build(activity_params)
    if @activity.save
      redirect_to course_activity_path(@course, @activity), notice: "Activity was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @activity.update(activity_params)
      redirect_to course_activity_path(@course, @activity), notice: "Activity was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @activity.destroy!
    redirect_to course_activities_path(@course), notice: "Activity was successfully destroyed.", status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_activity
    @activity = @course.activities.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:activity_type, :start_time, :end_time, :location, :description)
  end
end
