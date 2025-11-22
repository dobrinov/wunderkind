class ProfilesController < AuthenticatedController
  def show
    @user = current_user
  end

  def update
    if current_user.update params.require(:user).permit(:name, :feedback_after_answer)
      redirect_to profile_path, notice: "Успешно обновление!"
    else
      render :show, status: :unprocessable_entity
    end
  end
end
