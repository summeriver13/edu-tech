class ContributionsController < ApplicationController
  before_action :require_login
  before_action :set_course
  before_action :require_course_member

  def index
    @contributions = scope.includes(:user).order(on_date: :desc)
    @contribution = @course.contributions.build(on_date: Date.current, status: "done")
    @percentages = contribution_percentages
    @contribution_total = @course.contributions.sum(:hours)
  end

  def create
    @contribution = @course.contributions.build(contribution_params.merge(user: current_user))
    if @contribution.save
      redirect_to course_contributions_path(@course), notice: "贡献已记录。"
    else
      redirect_to course_contributions_path(@course), alert: @contribution.errors.full_messages.to_sentence
    end
  end

  def destroy
    contribution = scope.find(params[:id])
    contribution.destroy!
    redirect_to course_contributions_path(@course), notice: "记录已删除。", status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def scope
    course_manager?(@course) ? @course.contributions : @course.contributions.where(user: current_user)
  end

  def contribution_percentages
    totals = @course.contributions.group(:user_id).sum(:hours)
    overall = totals.values.sum
    return {} if overall.zero?

    totals.transform_values { |hours| (hours / overall * 100).round(1) }
  end

  def contribution_params
    params.require(:contribution).permit(:on_date, :task, :hours, :evidence_url, :status)
  end
end
