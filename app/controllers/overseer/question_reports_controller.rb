module Overseer
  # The queue of questions students have flagged. Keyed by question rather than
  # by report: several students reporting the same broken problem is one thing
  # to read and one edit to make, so every action here closes the whole pile.
  class QuestionReportsController < BaseController
    def index
      @questions = QuestionReport.open_questions.
        includes(:topics, reports: :user).
        page(params[:page]).per(25)
    end

    # Looked at and dealt with — typically after editing the question.
    def resolve
      close_pile :resolved, t("overseer.reports.resolved")
    end

    # Nothing wrong with the question.
    def dismiss
      close_pile :dismissed, t("overseer.reports.dismissed")
    end

    # Out of circulation until someone fixes it: back to draft, which is the
    # one status no practice session, homework or duel draws from.
    def withdraw
      question = Question.find(params[:question_id])
      question.update!(status: :draft)
      QuestionReport.close_pile!(question: question, status: :resolved, by: current_user)

      redirect_to overseer_question_reports_path, notice: t("overseer.reports.withdrawn")
    end

    private

    def close_pile(status, notice)
      QuestionReport.close_pile!(question: Question.find(params[:question_id]), status: status, by: current_user)
      redirect_to overseer_question_reports_path, notice: notice
    end
  end
end
