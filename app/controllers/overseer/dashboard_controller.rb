module Overseer
  # „Табло": where an admin lands. Two halves for the two hats — what is
  # waiting on the team, and, for an admin who is also a parent, a glance at
  # their own children with the shortest way to hand the tablet over. The
  # glance is only a glance: goals, focus and rewards stay on „Семейство".
  class DashboardController < BaseController
    def show
      @reports_waiting = TeamInbox.reports_waiting
      @suggestions_waiting = TeamInbox.suggestions_waiting
      @with_students = TeamInbox.with_students
      @latest = TeamInbox.latest
      @my_children_ids = current_user.children.ids
      @overviews = current_user.children.order(:name).map { |child| ChildOverview.new(child) }
      @owed = GoalAward.unused.joins(:goal).where(goals: { child_id: @my_children_ids }).includes(goal: :child).recent_first
    end
  end
end
