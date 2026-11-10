class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params.merge(role: "member"))

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to root_path, notice: "注册成功，欢迎 #{@user.name}。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:name, :password, :password_confirmation)
  end
end
