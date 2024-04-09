class ResourcesController < ApplicationController
  before_action :set_course
  def index

  end

  def show
    @resource = @course.resources.find(params[:id])
  end

  def new

  end

  def edit

  end

  def update

  end

  def create
    @resource = @course.resources.create(resource_params)
    redirect_to course_path(@course)
  end

  def destroy
    @resource = @course.resources.find(params[:id])
    @resource.destroy
    redirect_to course_path(@course), status: :see_other
  end

  private
  def set_course
    @course = Course.find(params[:course_id])
  end

  def resource_params
    params.require(:resource).permit(:name, :description, :video, :image)
  end
end
