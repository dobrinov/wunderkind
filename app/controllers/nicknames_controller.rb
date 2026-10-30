# The one question between a student and anything another child will see:
# what to call them. Without a nickname a student was „Противник" in friend
# requests, invitations and duels — two siblings in the family field test duelled
# without knowing it was each other — and missing from the weekly board they
# were leading. AuthenticatedController#require_nickname sends a student here
# from the duel, the friends list, the leaderboard and the leagues, and back.
class NicknamesController < AuthenticatedController
  def new
    @return_to = helpers.internal_path(params[:return_to], challenges_path)
  end

  def create
    @return_to = helpers.internal_path(params[:return_to], challenges_path)
    nickname = params[:nickname].to_s.strip

    if nickname.blank?
      flash.now[:alert] = t("nicknames.blank")
      return render :new, status: :unprocessable_content
    end

    current_user.nickname = nickname
    if current_user.save
      redirect_to @return_to
    else
      flash.now[:alert] = current_user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_content
    end
  end
end
