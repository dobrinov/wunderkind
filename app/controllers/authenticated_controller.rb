class AuthenticatedController < ApplicationController
  before_action :require_login

  private

  def require_login
    redirect_to sign_in_path, alert: t("auth.must_sign_in") unless current_user
  end
end
