module Teachers
  class BaseController < AuthenticatedController
    before_action :require_teacher
    before_action :require_verified_email, unless: -> { request.get? }

    private

    def require_teacher
      redirect_to root_path unless current_user.teacher? || current_user.admin?
    end

    def require_verified_email
      return if current_user.verified?

      redirect_back fallback_location: teachers_classrooms_path, alert: t("verification.required")
    end
  end
end
