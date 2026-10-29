# The „Ново за теб" sheet's two answers: „Опитай" goes to the feature, „По-късно"
# goes back where the child was. Both record that the child has been told
# (users.introduced_features), because a sheet that reappears until it is
# obeyed is a sheet children learn to swipe away unread. The duel's sheet also
# asks for a nickname when there is none — the one thing a duel, a friend list
# and a leaderboard cannot show a child without, and the reason the board used
# to greet every new student with an empty list.
class IntroductionsController < AuthenticatedController
  FEATURE_PATHS = {
    "review" => :review_path, "badges" => :profile_path, "duel" => :challenges_path,
    "friends" => :friends_path, "leaderboards" => :leaderboard_path,
    "competitions" => :competitions_path, "suggest" => :new_suggestion_path
  }.freeze

  def update
    feature = params[:feature].to_s
    return head :not_found unless FEATURE_PATHS.key?(feature)

    nickname = params[:nickname].to_s.strip
    current_user.nickname = nickname if nickname.present? && current_user.nickname.blank?
    current_user.introduced_features |= [ feature ]

    unless current_user.save
      return redirect_to home_path, alert: current_user.errors.full_messages.to_sentence
    end

    track :introduction_answered, feature: feature, choice: params[:go].present? ? "try" : "later"
    if params[:go].present?
      redirect_to public_send(FEATURE_PATHS.fetch(feature))
    else
      redirect_to home_path
    end
  end
end
