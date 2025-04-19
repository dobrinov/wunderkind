class CalendarsController < AuthenticatedController
  layout "application"

  def show
    @calendar = Calendar.new current_user
  end
end
