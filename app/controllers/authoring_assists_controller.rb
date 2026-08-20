# In-editor AI assistance for question authors (teachers and admins).
class AuthoringAssistsController < AuthenticatedController
  before_action :require_author_role

  rate_limit to: 10, within: 1.minute

  def create
    suggestions = Ai::AuthoringAssistant.call(
      kind: params[:kind],
      body_text: params[:body_text].to_s.first(2000),
      answer: params[:answer].to_s.first(500)
    )

    render json: { suggestions: suggestions }
  rescue Ai::Unavailable => error
    render json: { error: t("assist.unavailable", reason: error.message) }, status: :service_unavailable
  rescue ArgumentError
    head :bad_request
  end

  private

  def require_author_role
    head :forbidden unless current_user.teacher? || current_user.admin?
  end
end
