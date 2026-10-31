module ParentMailerHelper
  # The sentences under one child's numbers in the weekly report, each only
  # when it has something to say — the same rule as the email itself.
  def entry_lines(entry)
    scope = "mailers.weekly_report.lines"
    lines = []

    change = entry.problems - entry.previous_problems
    lines << if entry.previous_problems.zero? then t("#{scope}.first_week")
    elsif change.positive? then t("#{scope}.more", count: change)
    elsif change.negative? then t("#{scope}.fewer", count: -change)
    else t("#{scope}.same")
    end

    lines << t("#{scope}.difficulty.#{entry.difficulty}") if entry.difficulty
    lines << t("#{scope}.level", band: entry.band.name, grades: entry.band.grades_label)
    lines << t("#{scope}.streak", count: entry.streak) if entry.streak >= 2
    lines << t("#{scope}.badges", count: entry.badges.size, names: entry.badges.to_sentence) if entry.badges.any?
    entry.rewards.each { |award| lines << t("#{scope}.reward", reward: award.reward) }
    lines << t("#{scope}.review", count: entry.review_count) if entry.review_count.positive?
    lines
  end
end
