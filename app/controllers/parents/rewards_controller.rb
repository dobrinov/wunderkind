module Parents
  # „Използвана". The hour of Minecraft has been played, the ice cream eaten —
  # the parent says so, and the reward stops being outstanding.
  #
  # Only ever marked used, never unmarked and never deleted: the list is a
  # record of what a child earned, and the one thing it must not do is quietly
  # lose an entry.
  class RewardsController < BaseController
    def update
      award = GoalAward.joins(:goal).where(goals: { parent_id: current_user.id }).find(params[:id])
      award.use!

      redirect_to parents_child_path(award.goal.child_id), notice: t("goals.reward_used")
    end
  end
end
