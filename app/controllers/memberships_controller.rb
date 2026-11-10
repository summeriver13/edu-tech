class MembershipsController < ApplicationController
  before_action :require_login
  before_action :set_course
  before_action :require_course_manager

  def index
    load_memberships
    @membership = @course.course_memberships.build
  end

  def create
    user = User.find_by(name: params[:user_name].to_s.strip)
    return redirect_to course_memberships_path(@course), alert: "找不到用户。" if user.nil?

    @membership = @course.course_memberships.build(user: user, role: params[:role])
    if @membership.save
      redirect_to course_memberships_path(@course), notice: "已加入 #{user.name}。", status: :see_other
    else
      load_memberships
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    membership = @course.course_memberships.find(params[:id])
    membership.destroy!
    redirect_to course_memberships_path(@course), notice: "已移除 #{membership.user.name}。", status: :see_other
  end

  private

  def load_memberships
    @memberships = paginate(@course.course_memberships.includes(:user).order(:role))
  end

  def set_course
    @course = Course.find(params[:course_id])
  end
end
