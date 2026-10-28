class ProfilesController < AuthenticatedController
  # „Аз": who the student is and how they are doing — the progress chart and
  # the answers by day moved here from the home page, which is now about what
  # to do next. A parent's profile has neither.
  def show
    @user = current_user
    return unless @user.student?

    @trend = PerformanceTrend.new(@user)
    @stats = AnswerStats.new(days: AnswerStats.range(params[:days]), user: @user)
  end

  def update
    if current_user.update profile_params
      redirect_to settings_path, notice: t("profile.saved")
    else
      @user = current_user
      render "settings/show", status: :unprocessable_entity
    end
  end

  def link_code
    current_user.ensure_link_code!
    redirect_to settings_path
  end

  private

def profile_params
  fields = [ :name, :nickname, :feedback_after_answer, :sound_effects, :daily_minutes_target ]
  # A school grade is only estimated for a child, and each optional email is
  # only offered to whoever it is for (EmailPreferences).
  fields += [ :birth_year, :grade_offset ] if current_user.student?
  fields += EmailPreferences.for(current_user).map(&:key)
  params.require(:user).permit(*fields)
end
end
