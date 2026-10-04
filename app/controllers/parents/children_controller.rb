module Parents
  class ChildrenController < BaseController
    def index
      @children = current_user.children.includes(:badge_awards)
    end

    # The parent's observation space: how the child is actually doing, how far
    # through each goal they are, and what they have earned. The performance
    # half is the same cards the child sees on their own home page — there is
    # no second way of drawing a nine-week history, and a parent comparing
    # notes with their child should be looking at the same picture.
    def show
      @child = current_user.children.find(params[:id])
      Goals.refresh!(@child)

      @history = PracticeHistory.new(@child)
      @trend = PerformanceTrend.new(@child)
      @band = RatingBand.new(@child.elo)
      @standings = Goals.standings(@child)
      @awards = GoalAward.joins(:goal).where(goals: { child_id: @child.id }).includes(:goal).recent_first
    end

    def new
    end

    # Two paths in: link an existing student by their link code, or create a
    # fresh child account (the usual route for younger kids).
    def create
      if params[:link_code].present?
        link_existing_child
      else
        create_child_account
      end
    end

    private

    def link_existing_child
      child = User.student.find_by(link_code: params[:link_code].to_s.strip.upcase)

      if child.nil?
        redirect_to new_parents_child_path, alert: t("parents.children.invalid_code")
      elsif current_user.children.include?(child)
        redirect_to parents_children_path, notice: t("parents.children.already_linked", name: child.name)
      else
        current_user.parent_links.create!(child: child)
        redirect_to parents_children_path, notice: t("parents.children.linked", name: child.name)
      end
    end

    # Email and password are optional: without them the child has no login of
    # their own and plays by switching profiles inside this parent's account,
    # which is the usual shape for a child too young for an email.
    def create_child_account
      child = User.create_managed_child!(
        parent: current_user,
        name: params[:name],
        email: params[:email],
        password: params[:password]
      )

      redirect_to parents_children_path, notice: t("parents.children.created", name: child.name)
    rescue ActiveRecord::RecordInvalid => error
      redirect_to new_parents_child_path, alert: error.record.errors.full_messages.join(", ")
    end
  end
end
