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

    # Looked at and dealt with — typically after editing the question. The
    # response is optional: the students are told it was fixed either way.
    def resolve
      close_pile :resolved, t("overseer.reports.resolved")
    end

    # Nothing wrong with the question. Not without saying why: a child told
    # „no problem" about a question they were sure was wrong learns nothing
    # but that reporting is pointless. A student already answered on their own
    # (reply) has been told why.
    def dismiss
      question = Question.find(params[:question_id])
      unexplained = QuestionReport.open.where(question: question, response: nil).exists?

      if params[:response].blank? && unexplained
        return redirect_to overseer_question_reports_path, alert: t("overseer.reports.dismiss_needs_reason")
      end

      close_pile :dismissed, t("overseer.reports.dismissed")
    end

    # Writes back to one student without closing their report or touching the
    # question — the pile is still there to be dealt with.
    def reply
      report = QuestionReport.open.where(question_id: params[:question_id]).find(params[:report_id])

      if params[:response].blank?
        redirect_to overseer_question_reports_path, alert: t("overseer.reports.reply_empty")
      else
        report.reply!(params[:response])
        redirect_to overseer_question_reports_path, notice: t("overseer.reports.replied", name: report.user.name)
      end
    end

    # Out of circulation until someone fixes it: back to draft, which is the
    # one status no practice session or duel draws from.
    def withdraw
      question = Question.find(params[:question_id])
      question.update!(status: :draft)
      QuestionReport.close_pile!(question: question, status: :resolved, by: current_user, response: params[:response])

      redirect_to overseer_question_reports_path, notice: t("overseer.reports.withdrawn")
    end

    private

    def close_pile(status, notice)
      QuestionReport.close_pile!(question: Question.find(params[:question_id]), status: status, by: current_user,
                                 response: params[:response])
      redirect_to overseer_question_reports_path, notice: notice
    end
  end
end
