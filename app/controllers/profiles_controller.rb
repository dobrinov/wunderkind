class ProfilesController < AuthenticatedController
  # „Аз": who the student is and how they are doing — the progress chart and
  # the answers by day moved here from the home page, which is now about what
  # to do next. A parent's profile has neither.
  def show
    @user = current_user
    return unless @user.student?

    @trend = PerformanceTrend.new(@user)
    @stats = AnswerStats.new(days: AnswerStats.range(params[:days]), user: @user)
    @weakest = TopicPractice.weakest(@user)
    Coins.refresh!(@user)
  end

  # One action, two answers. The forms in Настройки post here as they always
  # did and get a redirect and a toast; the switches there save the moment
  # they are flipped, by fetch (settings_switches_controller.js), and get JSON
  # back — the values that were actually written, so a field this account may
  # not set (the daily minutes once a parent is linked, an email it is not
  # offered) comes back missing and the switch is put back, rather than a 204
  # that reads as „saved" for something `permit` quietly dropped.
  def update
    attributes = profile_params
    saved = current_user.update(attributes)

    respond_to do |format|
      format.html do
        if saved
          redirect_to settings_path, notice: t("profile.saved")
        else
          @user = current_user
          render "settings/show", status: :unprocessable_entity
        end
      end
      format.json do
        if saved
          render json: attributes.keys.index_with { |key| current_user.public_send(key) }
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def link_code
    current_user.ensure_link_code!
    redirect_to settings_path
  end

  private

def profile_params
  fields = [ :name, :nickname, :feedback_after_answer, :sound_effects ]
  # Once a parent is linked, the session length is theirs to set
  # (Parents::DailyMinutesController); the form only shows the number then.
  fields << :daily_minutes_target unless current_user.parents.exists?
  # A school grade is only estimated for a child, and each optional email is
  # only offered to whoever it is for (EmailPreferences).
  fields += [ :birth_year, :grade_offset ] if current_user.student?
  fields += EmailPreferences.for(current_user).map(&:key)
  params.require(:user).permit(*fields)
end
end
