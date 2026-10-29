module Overseer
  # Student reports as tickets. The list is filtered like an issue tracker —
  # waiting on us by default — and each report opens on a page of its own:
  # the question and the complaint, the conversation with a comment box, and
  # a status dropdown. Several students reporting one question are linked
  # tickets: a comment, a status change or withdrawing the question can be
  # applied to the other active ones in the same stroke.
  class QuestionReportsController < BaseController
    FILTERS = %w[waiting active closed all].freeze

    before_action :find_report, except: :index
    before_action :require_known_corrected_question, only: %i[comment transition]

    def index
      @filter = FILTERS.include?(params[:filter]) ? params[:filter] : FILTERS.first
      scope = { "waiting" => QuestionReport.awaiting_team, "active" => QuestionReport.active,
                "closed" => QuestionReport.closed, "all" => QuestionReport.all }.fetch(@filter)
      if params[:question_id].present?
        @question = Question.find(params[:question_id])
        scope = scope.where(question: @question)
      end
      @counts = { "waiting" => QuestionReport.awaiting_team.count, "active" => QuestionReport.active.count }
      @reports = scope.includes(:user, :question, messages: :author).order(updated_at: :desc).page(params[:page]).per(50)
    end

    def show
      @related = @report.question.reports.where.not(id: @report.id).includes(:user).order(:created_at)
    end

    # A comment. On a new report it starts the discussion (in progress).
    def comment
      if params[:body].blank? && corrected_question.nil?
        return back_to_report(alert: t("overseer.reports.reply_empty"))
      end

      targets.each { |report| report.team_reply!(by: current_user, body: params[:body], corrected_question: corrected_question) }
      back_to_report(notice: t("overseer.reports.replied"))
    end

    # The status dropdown. Fixed needs the version of the question that is
    # fixed — the student is asked to try it — and „not a problem" needs the
    # reason, because a child told „no problem" about a question they were sure
    # was wrong learns nothing but that reporting is pointless.
    def transition
      status = params[:status].to_s
      return back_to_report(alert: t("overseer.reports.unknown_status")) unless status.in?(%w[in_progress resolved dismissed])
      if status == "resolved" && corrected_question.nil?
        return back_to_report(alert: t("overseer.reports.resolve_needs_version"))
      end
      if status == "dismissed" && params[:body].blank?
        return back_to_report(alert: t("overseer.reports.dismiss_needs_reason"))
      end

      # Only „not a problem" carries words; anything else for the student is
      # a comment (#comment), so a stray field from a status the admin moved
      # away from is not sent.
      body = status == "dismissed" ? params[:body] : nil
      targets.each do |report|
        report.team_set_status!(status, by: current_user, body: body, corrected_question: corrected_question)
      end
      back_to_report(notice: t("overseer.reports.status_changed", status: t("report_thread.statuses.#{status}")))
    end

    # Out of circulation until someone fixes it: back to draft, which is the
    # one status no practice session or duel draws from. Every active report
    # on the question stays in progress — the students are still owed an
    # answer about the fix.
    def withdraw
      question = @report.question
      question.update!(status: :draft)
      ([ @report ] + question.reports.active.where.not(id: @report.id).to_a).uniq.each do |report|
        report.team_withdraw!(by: current_user, body: params[:body]) unless report.closed?
      end

      back_to_report(notice: t("overseer.reports.withdrawn"))
    end

    private

    def find_report
      @report = QuestionReport.includes(:question, :user, messages: [ :author, :corrected_question ]).find(params[:id])
    end

    # This report, plus the other active reports on the same question when the
    # admin ticked „apply to the others too".
    def targets
      others = params[:apply_to_related] == "1" ? @report.question.reports.active.where.not(id: @report.id).to_a : []
      [ @report ] + others
    end

    # The fixed version, typed as a question number or pasted as any link that
    # ends in one (the edit page, the preview). The reported question's own
    # number means it was fixed in place.
    def corrected_question
      return @corrected_question if defined?(@corrected_question)

      id = params[:corrected_question].to_s[/(\d+)\D*\z/, 1]
      @corrected_question = id && Question.find_by(id: id)
    end

    def require_known_corrected_question
      return if params[:corrected_question].blank? || corrected_question

      back_to_report(alert: t("overseer.reports.corrected_unknown"))
    end

    def back_to_report(**flash_message)
      redirect_to overseer_question_report_path(@report), **flash_message
    end
  end
end
