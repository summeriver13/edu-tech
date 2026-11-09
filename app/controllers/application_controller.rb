class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    session[:return_to] = request.fullpath if request.get?
    redirect_to new_session_path, alert: "请先登录。"
  end
end
