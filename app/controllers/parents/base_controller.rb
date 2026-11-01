module Parents
  class BaseController < AuthenticatedController
    before_action :require_parent
    before_action :require_verified_email, unless: -> { request.get? }
    before_action -> { remember_workspace("family") }

    private

    def require_parent
      redirect_to root_path unless current_user.parent? || current_user.admin?
    end

    # The email gate is about other people's children: an address nobody has
    # shown to be theirs must not take hold of a child who has a login and a
    # life of their own. A parent whose children are all managed accounts —
    # made inside this family, reachable only through it — touches nobody
    # else's, so they are let through before confirming. Confirming used to be
    # the first step of a parent's first run, and in production every parent
    # who left without adding a child had confirmed and then not come back to
    # the form (a link opened in the mail app lands in another browser).
    # What does reach somebody else stays behind `require_confirmed_address`:
    # linking a child by code, and inviting another parent by email.
    def require_verified_email
      return if current_user.verified? || only_managed_children?

      refuse_unverified
    end

    def require_confirmed_address
      refuse_unverified unless current_user.verified?
    end

    def only_managed_children?
      !current_user.children.where(managed_by_id: nil).exists?
    end

    def refuse_unverified
      redirect_back fallback_location: parents_children_path, alert: t("verification.required")
    end
  end
end
