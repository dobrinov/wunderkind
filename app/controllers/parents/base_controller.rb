module Parents
  class BaseController < AuthenticatedController
    before_action :require_parent
    before_action :require_verified_email, unless: -> { request.get? }

    private

    def require_parent
      redirect_to root_path unless current_user.parent? || current_user.admin?
    end

    def require_verified_email
      return if current_user.verified?

      redirect_back fallback_location: parents_children_path, alert: t("verification.required")
    end
  end
end
