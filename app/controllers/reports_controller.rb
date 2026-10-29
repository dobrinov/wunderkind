# „Моите сигнали" — every question this student reported, what came of it, the
# admin's reply and, once a question has been fixed, what changed in it. Opening
# the page is reading the replies, so it clears the count on „Аз" — except
# while an admin is looking: the replies are the child's to read.
class ReportsController < AuthenticatedController
  layout "application"

  def index
    @reports = current_user.question_reports.includes(:question).
      order(Arel.sql("COALESCE(resolved_at, updated_at) DESC")).page(params[:page])
    @unseen_ids = current_user.question_reports.unseen_replies.pluck(:id)
    current_user.question_reports.unseen_replies.update_all(response_seen_at: Time.current) unless impersonating?
  end
end
