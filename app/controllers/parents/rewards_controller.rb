module Parents
  # „Използвана". The hour of Minecraft has been played, the ice cream eaten —
  # the parent says so, and the reward stops being outstanding.
  #
  # Only ever marked used, never unmarked and never deleted: the list is a
  # record of what a child earned, and the one thing it must not do is quietly
  # lose an entry.
  #
  # Any parent of the child may mark it, not only the one who promised it: two
  # parents read the same owed list, and whoever handed the reward over says
  # so — which clears it for both, so nobody gives it a second time.
  class RewardsController < BaseController
    def update
      award = GoalAward.joins(:goal).where(goals: { child_id: current_user.children.select(:id) }).find(params[:id])
      award.use!

      redirect_to parents_child_path(award.goal.child_id, tab: "goals"), notice: t("goals.reward_used")
    end
  end
end
