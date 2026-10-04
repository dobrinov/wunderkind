module Parents
  # Setting and retiring a goal. There is no edit: a goal is a promise made in
  # particular words, and quietly rewriting one mid-week would change what a
  # child is working towards without them being told. Retiring it and setting a
  # new one says the same thing out loud — and the rewards already earned keep
  # the wording they were earned under either way (GoalAward#reward).
  class GoalsController < BaseController
    def new
      @child = find_child
      @goal = Goal.new(default_attributes)
    end

    def create
      @child = find_child
      @goal = Goal.new(goal_params.merge(parent: current_user, child: @child))

      if @goal.save
        redirect_to parents_child_path(@child), notice: t("goals.created")
      else
        flash.now[:alert] = @goal.errors.full_messages.join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    # Archived rather than deleted: the awards hang off it, and a child who
    # earned an hour of Minecraft in March should still be owed it in April.
    def destroy
      goal = current_user.set_goals.find(params[:id])
      goal.archive!

      redirect_to parents_child_path(goal.child), notice: t("goals.archived")
    end

    private

    def find_child
      current_user.children.find(params[:child_id])
    end

    def default_attributes
      { metric: :minutes, mode: :daily, period: :week, threshold: DailyPractice::DEFAULT_MINUTES, target: 5 }
    end

    # The two modes each carry their own number, because one field named for
    # both would have let the row the parent did not pick overwrite the row
    # they did. Whichever belongs to the chosen mode becomes `target`, and the
    # other columns are cleared rather than left holding a number that means
    # nothing in the mode that was saved.
    def goal_params
      attributes = params.require(:goal).
        permit(:metric, :mode, :period, :target, :total_target, :threshold, :ends_on, :reward).
        with_defaults(starts_on: Time.zone.today)

      attributes[:target] = attributes.delete(:total_target) unless attributes[:mode] == "daily"
      attributes.delete(:total_target)
      attributes[:threshold] = nil unless attributes[:mode] == "daily"
      attributes[:ends_on] = nil unless attributes[:period] == "once"
      attributes
    end
  end
end
