class DesignSystemController < ApplicationController
  layout "admin"

  before_action :require_access

  def show
  end

  private

  # Open in development; admin-only in production.
  def require_access
    return if Rails.env.development?

    redirect_to root_path unless current_user&.admin?
  end
end
