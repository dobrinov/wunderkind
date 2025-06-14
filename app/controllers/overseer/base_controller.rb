module Overseer
  class BaseController < AuthenticatedController
    before_action :require_admin
    layout "admin"

    private

    def require_admin
      redirect_to root_path unless current_user.admin?
    end
  end
end
