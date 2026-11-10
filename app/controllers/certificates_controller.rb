class CertificatesController < ApplicationController
  def show
    @certificate = Certificate.includes(:course, :user).find_by!(serial: params[:serial])
  end
end
