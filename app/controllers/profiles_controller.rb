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
    permitted = params.require(:user).permit(:name, :nickname, :feedback_after_answer, :sound_effects, :daily_minutes_target,
                                             :birth_year, :grade_offset, :weekly_report)
    # A grown-up has no school grade to estimate, and a child has no children to
    # be sent a report on; each field is only drawn for the one it is about.
    current_user.student? ? permitted.except(:weekly_report) : permitted.except(:birth_year, :grade_offset)
  end
end
