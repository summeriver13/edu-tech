class GroupMembershipsController < ApplicationController
  before_action :require_login
  before_action :set_course
  before_action :require_course_manager

  def create
    group = @course.groups.find(params[:group_id])
    user = User.find_by(name: params[:user_name])

    if user.nil?
      return redirect_to course_groups_path(@course), alert: "找不到用户。"
    end

    membership = group.group_memberships.build(user: user, role: params[:role], module_name: params[:module_name])
    if membership.save
      redirect_to course_groups_path(@course), notice: "已加入 #{user.name}。"
    else
      redirect_to course_groups_path(@course), alert: membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    group = @course.groups.find(params[:group_id])
    membership = group.group_memberships.find(params[:id])
    name = membership.user.name
    membership.destroy!
    redirect_to course_groups_path(@course), notice: "已移除 #{name}。", status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end
end
