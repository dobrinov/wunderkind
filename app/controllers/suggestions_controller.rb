# The suggestion flow, open to every role: propose a problem, watch what
# became of it, and talk about it with the team. Publishing stays with the
# admin inbox — a suggestion is never live until a human accepts it. Each
# suggestion is a ticket (QuestionReport, kind suggestion) whose conversation
# lives with the reports at /reports/:id; while it waits in review its author
# can change it here, and the change is recorded in that conversation.
class SuggestionsController < AuthenticatedController
  before_action :find_editable, only: %i[edit update]

  def index
    @suggestions = Question.where(suggested_by: current_user).includes(:topics).order(created_at: :desc).page params[:page]
    @tickets = current_user.question_reports.suggestion.where(question_id: @suggestions.map(&:id)).includes(:messages).index_by(&:question_id)
  end

  def new
    @suggestion = Suggestion.new
  end

  def create
    @suggestion = Suggestion.new(suggestion_params.merge(suggested_by: current_user))

    if @suggestion.save
      track :problem_suggested, answer_type: @suggestion.answer_type
      redirect_to suggestions_path, notice: t("suggestions.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @suggestion = Suggestion.editing(@question)
  end

  def update
    @suggestion = Suggestion.editing(@question)
    @suggestion.assign_attributes(suggestion_params.except(:note))

    if @suggestion.save
      redirect_to report_path(@ticket), notice: t("suggestions.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Only the author's own suggestion, and only while it still waits: once
  # accepted it is a bank question like any other, and once returned the
  # conversation is the way back in.
  def find_editable
    @question = Question.in_review.where(suggested_by: current_user).find(params[:id])
    @ticket = current_user.question_reports.suggestion.active.find_by!(question: @question)
  end

  def suggestion_params
    params.require(:suggestion).permit(:text, :answer_type, :answer, :explanation, :topic_id, :image, :note,
                                       options: [ :value, :correct ])
  end
end
