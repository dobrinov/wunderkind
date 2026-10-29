module Parents
  # How long a child's daily session is. The parent's call for any child they
  # are linked to, managed or not, which is why the child's own settings show
  # the number without a field once a parent is linked — see
  # SettingsController. Anything off DailyPractice::MINUTES_OPTIONS is refused
  # quietly, the way a fiddled form is everywhere else.
  class DailyMinutesController < BaseController
    def update
      child = current_user.children.find(params[:child_id])
      minutes = params[:minutes].to_i

      if DailyPractice::MINUTES_OPTIONS.include?(minutes)
        child.update!(daily_minutes_target: minutes)
        track :daily_minutes_set, minutes: minutes
        flash[:notice] = t("parents.daily_minutes.saved", name: child.name, count: minutes)
      end

      # On „Какво упражнява", beside the focus: how long a session is belongs
      # with what it is about.
      redirect_to parents_child_path(child, tab: "practice", anchor: "daily-minutes")
    end
  end
end
