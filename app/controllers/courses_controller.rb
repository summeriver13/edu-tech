class CoursesController < ApplicationController
  PER_PAGE = 9
  PUBLIC_MAX_AGE = 120

  before_action :require_login, only: %i[ new create edit update destroy sync ]
  before_action :require_admin, only: %i[ new create destroy ]
  before_action :set_course, only: %i[ show edit update destroy sync preview ]
  before_action :require_course_manager, only: %i[ edit update sync preview ]

  # GET /courses or /courses.json
  def index
    @query = params[:q].to_s.strip
    @courses = paginate(Course.search(@query).order(created_at: :desc), per: PER_PAGE)
  end

  def show
    @resources = @course.resources.order(:name)
    @activities = @course.activities.order(start_time: :desc)
    @assessments = @course.assessments.order(:due_at)
    @lessons = @course.lessons
    @completed_lesson_ids = logged_in? ? LessonCompletion.where(user: current_user, lesson: @lessons).pluck(:lesson_id) : []
    @lesson_progress = @course.lesson_progress_for(logged_in? ? current_user : nil)
    @certificate = logged_in? ? @course.certificates.find_by(user: current_user) : nil
    fresh_when(
      etag: [ @course, content_updated_at, current_user&.id, @completed_lesson_ids.sort, @lesson_progress, @certificate&.id ],
      last_modified: content_updated_at,
      public: !logged_in?
    )
    response.cache_control[:max_age] = PUBLIC_MAX_AGE unless logged_in?
  end

  def information
    @course = Course.find(params[:id])
  end

  def new
    @course = Course.new
  end

  # GET /courses/1/edit
  def edit
  end

  # GET /courses/1/preview
  def content_updated_at
    [
      @course.updated_at,
      @course.assessments.maximum(:updated_at),
      @course.lessons.maximum(:updated_at),
      @course.resources.maximum(:updated_at),
      @course.activities.maximum(:updated_at)
    ].compact.max
  end

  def preview
    if @course.syncing_at.present?
      redirect_to course_path(@course), alert: "同步正在进行。"
      return
    end

    result = CourseRepo.new(@course).preview
    unless result.success?
      redirect_to course_path(@course), alert: result.message
      return
    end

    @changes = result.changes
    @message = result.message
  end

  # POST /courses/1/sync
  def sync
    if @course.syncing_at.present?
      redirect_to course_path(@course), alert: "同步正在进行。", status: :see_other
      return
    end

    @course.update!(syncing_at: Time.current, sync_error: nil)
    CourseSyncJob.perform_later(@course)
    redirect_to course_path(@course), notice: "同步已开始，完成后刷新页面。", status: :see_other
  end

  # POST /courses or /courses.json
  def create
    @course = Course.new(course_params)

    respond_to do |format|
      if @course.save
        format.html { redirect_to course_url(@course), notice: "Course was successfully created." }
        format.json { render :show, status: :created, location: @course }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /courses/1 or /courses/1.json
  def update
    respond_to do |format|
      if @course.update(course_params)
        format.html { redirect_to course_url(@course), notice: "Course was successfully updated." }
        format.json { render :show, status: :ok, location: @course }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /courses/1 or /courses/1.json
  def destroy
    @course.destroy!

    respond_to do |format|
      format.html { redirect_to courses_url, notice: "Course was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_course
      @course = Course.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def course_params
      params.require(:course).permit(:title, :course_number, :description, :cover, :credit, :repo_url, :time_zone, :week1_start, :term_weeks, :late_penalty_percent, :late_penalty_max_days, :census_at, :min_attendance, :self_enrollment)
    end
end
