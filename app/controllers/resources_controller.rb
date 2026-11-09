class ResourcesController < ApplicationController
  before_action :require_login, only: %i[ new edit create update destroy ]
  before_action :set_course
  before_action :set_resource, only: %i[ show edit update destroy ]

  def index
    @resources = @course.resources
  end

  def show
  end

  def new
    @resource = @course.resources.build
  end

  def edit
  end

  def create
    @resource = @course.resources.build(resource_params)
    if @resource.save
      redirect_to course_resource_path(@course, @resource), notice: "Resource was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @resource.update(resource_params)
      redirect_to course_resource_path(@course, @resource), notice: "Resource was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @resource.destroy!
    redirect_to course_resources_path(@course), notice: "Resource was successfully destroyed.", status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_resource
    @resource = @course.resources.find(params[:id])
  end

  def resource_params
    params.require(:resource).permit(:name, :resource_type, :url, :description, :video)
  end
end
