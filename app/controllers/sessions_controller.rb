class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(name: params[:name])

    if user&.authenticate(params[:password].to_s)
      return_to = session[:return_to]
      reset_session
      session[:user_id] = user.id
      redirect_to return_to || root_path, notice: "登录成功，欢迎 #{user.name}。"
    else
      flash.now[:alert] = "用户名或密码错误。"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "已登出。", status: :see_other
  end
end
