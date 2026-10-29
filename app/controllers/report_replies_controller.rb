# A student saying „разбрах" to the answer on a question they reported, which
# takes it off „Днес". Only their own: the report is looked up among theirs.
class ReportRepliesController < AuthenticatedController
  def update
    current_user.question_reports.answered.find(params[:id]).mark_reply_seen!
    redirect_to home_path
  end
end
