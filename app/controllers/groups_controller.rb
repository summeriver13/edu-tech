class GroupsController < ApplicationController
  before_action :require_login
  before_action :set_course
  before_action :require_course_member
  before_action :require_course_manager, only: %i[ create destroy ]

  def index
    @groups = @course.groups.includes(group_memberships: :user).order(:name)
    @group = @course.groups.build
    @percentages = @course.groups.to_h { |group| [ group.id, group.contribution_percentages ] }
    @names = User.where(id: @groups.flat_map { |group| group.group_memberships.map(&:user_id) }).pluck(:id, :name).to_h
  end

  def create
    @group = @course.groups.build(group_params)
    if @group.save
      redirect_to course_groups_path(@course), notice: "小组已创建。"
    else
      redirect_to course_groups_path(@course), alert: @group.errors.full_messages.to_sentence
    end
  end

  def destroy
    group = @course.groups.find(params[:id])
    group.destroy!
    redirect_to course_groups_path(@course), notice: "小组已删除。", status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def group_params
    params.require(:group).permit(:name)
  end
end
