# The first-run tour on „Днес" is over — finished or skipped, the same answer:
# it is shown once (users.toured_at). Called by tour_controller.js with fetch,
# so it answers with no content rather than a page.
class ToursController < AuthenticatedController
  def update
    current_user.update_column(:toured_at, Time.current) if current_user.toured_at.nil?
    head :no_content
  end
end
