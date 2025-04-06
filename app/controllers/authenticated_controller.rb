class AuthenticatedController < ApplicationController
  before_action :require_login

  private

  def require_login
    redirect_to sign_in_path, alert: "Моля, влезте в системата" unless current_user
  end
end
