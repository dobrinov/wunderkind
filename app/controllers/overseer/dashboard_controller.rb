module Overseer
  # „Табло": where an admin lands. Two halves for the two hats — what is
  # waiting on the team, and, for an admin who is also a parent, a glance at
  # their own children with the shortest way to hand the tablet over. The
  # glance is only a glance: goals, focus and rewards stay on „Семейство".
  class DashboardController < BaseController
    def show
      waiting = TeamInbox.by_kind
      @reports_waiting = waiting["report"]
      @suggestions_waiting = waiting["suggestion"]
      @with_students = TeamInbox.with_students
      @latest = TeamInbox.latest
      @struggling = Attention.struggling_students.reject { |entry| entry.user.admin? }
      @hard_questions = Attention.hard_questions
      @my_children_ids = current_user.children.ids
      @overviews = current_user.children.order(:name).map { |child| ChildOverview.new(child) }
      @owed = GoalAward.unused.joins(:goal).where(goals: { child_id: @my_children_ids }).includes(goal: :child).recent_first
    end
  end
end
