module Overseer
  # The queue of questions students have flagged. Keyed by question rather than
  # by report: several students reporting the same broken problem is one thing
  # to read and one edit to make. Every action takes the whole pile of active
  # reports on the question, or — with `report_id` — one student's report, so
  # a single conversation can be answered or closed on its own.
  class QuestionReportsController < BaseController
    before_action :require_known_corrected_question, except: :index

    def index
      @questions = QuestionReport.open_questions.
        includes(:topics, reports: [ :user, { messages: [ :author, :corrected_question ] } ]).
        page(params[:page]).per(25)
    end

    # A word to the students, without closing anything: the discussion is on.
    def reply
      if params[:body].blank? && corrected_question.nil?
        return back_with_alert("overseer.reports.reply_empty")
      end

      reports.each { |report| report.team_reply!(by: current_user, body: params[:body], corrected_question: corrected_question) }
      redirect_to overseer_question_reports_path, notice: t("overseer.reports.replied")
    end

    # Looked at and dealt with — typically after editing the question. The
    # message is optional: the students are told it was fixed either way.
    def resolve
      reports.each { |report| report.team_close!(:resolved, by: current_user, body: params[:body], corrected_question: corrected_question) }
      redirect_to overseer_question_reports_path, notice: t("overseer.reports.resolved")
    end

    # Nothing wrong with the question. Not without saying why: a child told
    # „no problem" about a question they were sure was wrong learns nothing
    # but that reporting is pointless. A student the team has already written
    # to in the thread has been told why.
    def dismiss
      if params[:body].blank? && reports.any? { |report| !report.team_has_written? }
        return back_with_alert("overseer.reports.dismiss_needs_reason")
      end

      reports.each { |report| report.team_close!(:dismissed, by: current_user, body: params[:body], corrected_question: corrected_question) }
      redirect_to overseer_question_reports_path, notice: t("overseer.reports.dismissed")
    end

    # Out of circulation until someone fixes it: back to draft, which is the
    # one status no practice session or duel draws from. The reports stay in
    # progress — the students are still owed an answer about the fix.
    def withdraw
      question.update!(status: :draft)
      reports.each { |report| report.team_withdraw!(by: current_user, body: params[:body], corrected_question: corrected_question) }

      redirect_to overseer_question_reports_path, notice: t("overseer.reports.withdrawn")
    end

    private

    def question
      @question ||= Question.find(params[:question_id])
    end

    def reports
      @reports ||= begin
        scope = question.reports.active.includes(messages: :author)
        params[:report_id].present? ? [ scope.find(params[:report_id]) ] : scope.to_a
      end
    end

    # „Поправена версия": the corrected question when the fix is a different
    # row, typed as its number or pasted as any link that ends in it (the edit
    # page, the preview). Blank means the fix, if any, is in the question itself.
    def corrected_question
      return @corrected_question if defined?(@corrected_question)

      id = params[:corrected_question].to_s[/(\d+)\D*\z/, 1]
      @corrected_question = id && Question.find_by(id: id)
    end

    def require_known_corrected_question
      return if params[:corrected_question].blank? || corrected_question

      back_with_alert("overseer.reports.corrected_unknown")
    end

    def back_with_alert(key)
      redirect_to overseer_question_reports_path(anchor: "question_#{params[:question_id]}"), alert: t(key)
    end
  end
end
