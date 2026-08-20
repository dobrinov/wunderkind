class ProfilesController < AuthenticatedController
  def show
    @user = current_user
  end

  def update
    if current_user.update profile_params
      redirect_to profile_path, notice: t("profile.saved")
    else
      @user = current_user
      render :show, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :nickname, :feedback_after_answer, :daily_minutes_target)
  end
end
