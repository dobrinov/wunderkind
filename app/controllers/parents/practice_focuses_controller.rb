module Parents
  # „Какво упражнява": general practice, or a focus on a few topics until a
  # target is reached — see PracticeFocus. One form, one „Запази", whichever
  # way it is set.
  #
  # Never an edit. Saving a focus archives the one in play and sets a new one,
  # the stance Goals takes for the same reason: a child working toward „кино в
  # събота" should not have the promise rewritten under them. Saving exactly
  # what is already set does nothing, so pressing „Запази" twice is not two
  # promises.
  class PracticeFocusesController < BaseController
    def update
      child = current_user.children.find(params[:child_id])

      if params[:mode] == "focus"
        set_focus(child)
      else
        clear_focus(child)
      end
    end

    private

    def set_focus(child)
      active = PracticeFocus.active.find_by(child: child)
      topic_ids = permitted_topic_ids(child, active)
      target = PracticeFocus.targets.key?(params[:target]) ? params[:target] : "step"
      reward = params[:reward].to_s.strip.presence

      return redirect_back_to_tab(child, alert: t("practice_focus.no_topics")) if topic_ids.empty?

      if active && active.topic_ids.sort == topic_ids.sort && active.target == target && active.reward == reward
        return redirect_back_to_tab(child, notice: t("practice_focus.unchanged"))
      end

      focus = PracticeFocuses.set!(child: child, parent: current_user, topic_ids: topic_ids, target: target, reward: reward)
      track :focus_set, target: focus.target
      redirect_back_to_tab(child, notice: t("practice_focus.saved", name: child.name))
    rescue ActiveRecord::RecordInvalid => error
      redirect_back_to_tab(child, alert: error.record.errors.full_messages.join(", "))
    end

    def clear_focus(child)
      had_focus = PracticeFocus.active.where(child: child).exists?
      PracticeFocuses.clear!(child)

      redirect_back_to_tab(child, notice: (t("practice_focus.cleared", name: child.name) if had_focus))
    end

    # What was offered on the page, plus whatever the focus in play already
    # holds: a topic that has gone thin since it was chosen stays choosable (the
    # page lists it with a note), anything else is dropped the way a stale form
    # is everywhere — see DuelCategories.selected.
    def permitted_topic_ids(child, active)
      kept = active ? active.topic_ids : []
      offered = PracticeFocuses.offer(child, keep: kept).flat_map { |group| group.entries.map { |entry| entry.topic.id } }

      (Array(params[:topic_ids]).map(&:to_i).uniq & offered).first(PracticeFocus::MAX_TOPICS)
    end

    def redirect_back_to_tab(child, **messages)
      redirect_to parents_child_path(child, tab: "practice"), messages.compact
    end
  end
end
