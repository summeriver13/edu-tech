class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]

  # GET /users or /users.json
  def index
    @users = User.all
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    file = params[:file] # 获取上传的文件
    key = SecureRandom.uuid # 生成唯一的文件名，你也可以根据需要修改文件名逻辑

    upload_to_qiniu(file, key) # 调用上传方法将文件上传到七牛云

    # 处理上传成功后的逻辑，例如保存文件信息到数据库等
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to user_url(@user), notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to user_url(@user), notice: "User was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_url, notice: "User was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:name, :password, :password_confirmation)
    end

    def upload_to_qiniu(file, key)
      bucket = 'rails-videos' # 七牛云存储空间名称
      put_policy = Qiniu::Auth::PutPolicy.new(bucket)
      token = Qiniu::Auth.generate_uptoken(put_policy)

      code, result, _response_headers = Qiniu::Storage.upload_with_token_2(
        token, file.path, key, nil, bucket: bucket
      )

      # 处理上传结果
      if code == 200
        Rails.logger.info "Upload success"
      else
        Rails.logger.error "Upload failed: #{result}"
      end
    end
end
