class CalendarsController < AuthenticatedController
  layout "application"

  def show
    @today = Date.current
    @start_date = @today.beginning_of_month.beginning_of_week
    @end_date = @today.end_of_month.end_of_week
    @assignments = current_user.assignments.where(completed_at: @start_date..@end_date)
    @completed_dates = @assignments.pluck(:completed_at).map(&:to_date).uniq
  end
end
