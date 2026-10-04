module GoalsHelper
  # A goal read back as the sentence a parent would say. „Поне 15 минути на
  # ден, 5 дни" rather than „minutes/daily/5/15", because every screen that
  # shows a goal — the parent's list, the child's card, the form's preview —
  # has to say the same thing in the same words.
  def goal_sentence(goal)
    unit = t("goals.metrics.#{goal.metric}")

    if goal.daily?
      t("goals.sentence.daily", threshold: goal.threshold, unit: unit, count: goal.target)
    else
      t("goals.sentence.total", count: goal.target, unit: unit)
    end
  end

  # When it has to be done by, and whether it comes round again.
  def goal_period_sentence(goal)
    return t("goals.period_sentence.once", date: l(goal.ends_on, format: :short)) if goal.once?

    t("goals.period_sentence.#{goal.period}")
  end

  # „от 28 септ до 4 окт" — which particular week or month is being counted.
  def goal_window(period)
    start, finish = period

    t("goals.window", from: l(start, format: :short), to: l(finish, format: :short))
  end
end
