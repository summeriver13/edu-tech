class PasswordsController < ApplicationController
  before_action :require_login

  def edit
  end

  def update
    unless current_user.authenticate(params[:current_password].to_s)
      flash.now[:alert] = "当前密码不正确。"
      return render :edit, status: :unprocessable_entity
    end

    if current_user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to root_path, notice: "密码已更新。"
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
