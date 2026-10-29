# „Моите сигнали" — the student's side of every question they reported. The
# list is in two tabs, the reports in play and the ones put away; each report
# opens as its thread: what they said, what the team said, the question before
# and after the fix, and a way to answer — including whether the fix fixed it.
#
# Opening a thread is reading it, so it clears the count on „Аз" — except while
# an admin is looking: the replies are the child's to read. Answering and
# archiving are writes, which an impersonated session is refused anyway.
class ReportsController < AuthenticatedController
  layout "application"

  def index
    @archived = params[:archived].present?
    mine = current_user.question_reports
    @active_count = mine.unarchived.count
    @archived_count = mine.archived.count
    @unread_ids = mine.unread.pluck(:id).to_set
    @reports = (@archived ? mine.archived : mine.unarchived).
      includes(:question, messages: :author).order(updated_at: :desc).page(params[:page])
  end

  def show
    @report = report
    @unread = @report.unread?
    @report.mark_seen! unless impersonating?
  end

  def respond
    if report.student_respond!(kind: params[:kind], body: params[:body])
      notice = t("my_reports.sent.#{params[:kind]}", default: t("my_reports.sent.comment"))
      redirect_to report_path(report), notice: notice
    else
      redirect_to report_path(report), alert: t("my_reports.empty_message")
    end
  end

  # „Опитай поправената задача": the fixed question as a session of one. The
  # thread stays where it is, so the verdict — „Оправено е" or not — is one
  # tap back.
  def attempt
    return redirect_to(report_path(report)) unless report.retryable?

    assignment = MistakePractice.retry(user: current_user, question: report.question)
    track :session_started, kind: assignment.kind
    redirect_to question_path(assignment.next_assignment_question)
  end

  def archive
    report.archive!
    redirect_to reports_path, notice: t("my_reports.archived_notice")
  end

  def unarchive
    report.unarchive!
    redirect_to report_path(report)
  end

  private

  def report
    @report ||= current_user.question_reports.includes(:question, messages: :author).find(params[:id])
  end
end
