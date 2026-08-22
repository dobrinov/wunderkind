# The suggestion flow, open to every role: propose a problem, watch what
# became of it. Publishing stays with the admin review queue — a suggestion is
# never live until a human approves it.
class SuggestionsController < AuthenticatedController
  def index
    @suggestions = Question.where(suggested_by: current_user).order(created_at: :desc).page params[:page]
  end

  def new
    @suggestion = Suggestion.new
  end

  def create
    @suggestion = Suggestion.new(suggestion_params.merge(suggested_by: current_user))

    if @suggestion.save
      redirect_to suggestions_path, notice: t("suggestions.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def suggestion_params
    params.require(:suggestion).permit(:text, :answer, :explanation, :topic_id)
  end
end
