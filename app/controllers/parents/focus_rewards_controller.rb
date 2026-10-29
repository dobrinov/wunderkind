module Parents
  # „Дадена": the reward for a completed focus has been handed over. The same
  # one-way switch as a goal's reward (RewardsController) — marked given, never
  # unmarked — but open to any parent of the child rather than only the one who
  # set it, because in a family it is whoever took them to the cinema.
  class FocusRewardsController < BaseController
    def update
      focus = PracticeFocus.where(child_id: current_user.children.select(:id)).find(params[:id])
      focus.give_reward!

      redirect_to parents_child_path(focus.child_id, tab: "practice"), notice: t("goals.reward_used")
    end
  end
end
