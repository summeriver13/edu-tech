class ApplicationController < ActionController::Base
  include Pagination
  helper_method :current_user, :logged_in?, :admin?, :course_manager?, :course_member?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def admin?
    current_user&.admin?
  end

  def require_login
    return if logged_in?

    session[:return_to] = request.fullpath if request.get?
    redirect_to new_session_path, alert: "请先登录。"
  end

  def require_admin
    return if admin?

    redirect_to root_path, alert: "需要管理员权限。"
  end

  def course_manager?(course)
    logged_in? && course.manageable_by?(current_user)
  end

  def course_member?(course)
    logged_in? && course.member?(current_user)
  end

  def require_course_member
    return if course_member?(@course)

    redirect_to root_path, alert: "需要课程成员身份。"
  end

  def require_course_manager
    return if course_manager?(@course)

    redirect_to root_path, alert: "需要课程管理权限。"
  end
end
