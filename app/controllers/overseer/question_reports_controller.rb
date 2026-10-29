module Overseer
  # One ticket — a student's report or somebody's suggested problem — on a
  # page of its own: the question as the reporter saw it beside the version
  # now, the conversation with a box to write in as „Екипът на Wunderkind",
  # the status as four choices, and the people and the other tickets on the
  # same question. Several students reporting one question are linked
  # tickets: a comment, a status change or withdrawing the question can be
  # applied to the other active ones in the same stroke.
  #
  # The list of tickets is the inbox (InboxController); this controller's
  # index only forwards the reports list's old links there, filter and all.
  # Every action can be sent back to where it was pressed from (`return_to`):
  # the inbox's side pane and review mode post here too.
  class QuestionReportsController < BaseController
    before_action :find_report, except: :index
    before_action :require_known_corrected_question, only: %i[comment transition]

    def index
      redirect_to overseer_inbox_path(params.permit(:filter, :question_id, :kind).to_h)
    end

    def show
      @inbox = TicketInbox.new(filter: params[:filter], kind: params[:kind], question_id: params[:question_id])
      @position = @inbox.position_of(@report)
      @related = @report.question.reports.where.not(id: @report.id).includes(:user).order(:created_at)
      @my_children_ids = current_user.children.ids
      checks = SuggestionChecks.new(@report.question)
      @template = checks.same_template
      @checks = checks if @report.suggestion?
    end

    # A comment. On a new ticket it starts the discussion (in progress); on a
    # suggestion it is „asking the author".
    def comment
      if params[:body].blank? && corrected_question.nil?
        return back_to_report(alert: t("overseer.reports.reply_empty"))
      end

      targets.each { |report| report.team_reply!(by: current_user, body: params[:body], corrected_question: corrected_question) }
      back_to_report(notice: t("overseer.reports.replied"))
    end

    # The status choice. Fixed needs the version of the question that is
    # fixed — the student is asked to try it — and „not a problem" needs the
    # reason, because a child told „no problem" about a question they were sure
    # was wrong learns nothing but that reporting is pointless. On a
    # suggestion still in review the two closing choices are accepting and
    # returning it.
    def transition
      status = params[:status].to_s
      return back_to_report(alert: t("overseer.reports.unknown_status")) unless status.in?(%w[in_progress resolved dismissed])
      return accept if status == "resolved" && @report.decidable?
      return decline if status == "dismissed" && @report.decidable?
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
      back_to_report(notice: t("overseer.reports.status_changed", status: helpers.ticket_status_label(@report.reload)))
    end

    # Accepting a suggestion: published, credited, the ticket closed with the
    # team's word. Review mode sends the topic and the rating it settled on.
    def accept
      return back_to_report(alert: t("overseer.inbox.not_decidable")) unless @report.decidable?

      elo = params[:elo].presence&.to_i
      topic = Topic.find_by(id: params[:topic_id]) if params[:topic_id].present?
      @report.accept!(by: current_user, body: params[:body], elo: elo&.clamp(0, 4000), topic: topic)
      back_to_report(notice: t("overseer.inbox.accepted"))
    end

    # Returning a suggestion, which needs the note the author reads — a
    # suggestion sent back with no word teaches only that suggesting is
    # pointless.
    def decline
      return back_to_report(alert: t("overseer.inbox.not_decidable")) unless @report.decidable?
      return back_to_report(alert: t("overseer.inbox.decline_needs_note")) if params[:body].blank?

      @report.decline!(by: current_user, body: params[:body])
      back_to_report(notice: t("overseer.inbox.declined"))
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
      redirect_to helpers.internal_path(params[:return_to], overseer_question_report_path(@report)), **flash_message
    end
  end
end
