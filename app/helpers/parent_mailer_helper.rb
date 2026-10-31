module ParentMailerHelper
  # The plain sentences under a child's numbers in the weekly report, in the
  # order a parent would ask about them. The change in problems is not here —
  # it sits beside the number itself — and the coins have a section of their own.
  def entry_lines(entry)
    scope = "mailers.weekly_report.lines"
    lines = []

    if entry.difficulty == :harder && entry.harder_weeks >= 2
      lines << t("#{scope}.harder_weeks", count: entry.harder_weeks)
    elsif entry.difficulty
      lines << t("#{scope}.difficulty.#{entry.difficulty}")
    end
    lines << t("#{scope}.first_week") if entry.previous_problems.zero?
    lines << t("#{scope}.level", band: entry.band.name, grades: entry.band.grades_label)
    lines << t("#{scope}.streak", count: entry.streak) if entry.streak >= 2
    lines << t("#{scope}.review", count: entry.review_count) if entry.review_count.positive?
    lines
  end

  # „+12" / „−23" beside the week's problems; nothing when there is no last
  # week to compare with or nothing changed.
  def problems_change(entry)
    return if entry.previous_problems.zero?

    change = entry.problems - entry.previous_problems
    return if change.zero?

    change.positive? ? [ "+#{change}", "#166534" ] : [ "−#{-change}", "#92400e" ]
  end

  # One bar per day, Monday to Sunday, as email-safe table cells: a fixed-
  # height cell holding a coloured block, since mail clients drop SVG.
  BAR_MAX_PX = 48

  def minute_bars(entry)
    peak = [ entry.days.map(&:minutes).max.to_f, 1 ].max
    entry.days.map do |day|
      minutes = day.minutes.round
      height = minutes.positive? ? [ (BAR_MAX_PX * day.minutes / peak).round, 6 ].max : 4
      { name: I18n.t("mailers.weekly_report.day_names")[day.date.cwday - 1], minutes: minutes, height: height, active: day.active? }
    end
  end

  def weekly_summary(report)
    t("mailers.weekly_report.summary", count: report.total_problems)
  end

  # „Мая: 5 дни, 52 задачи · Боби: 2 дни, 18 задачи" — what the inbox shows
  # under the subject.
  def weekly_preheader(report)
    parts = report.children.map do |entry|
      "#{entry.child.name}: #{entry.active_days} #{t("mailers.weekly_report.stats.days", count: entry.active_days)}, " \
        "#{entry.problems} #{t("mailers.weekly_report.stats.problems", count: entry.problems)}"
    end
    parts << t("mailers.weekly_report.owed.title", count: report.owed.size) if report.owed.any?
    parts.join(" · ")
  end

  def quiet_line(quiet)
    if quiet.days_since
      t("mailers.weekly_report.quiet.since", name: quiet.child.name, count: quiet.days_since)
    else
      t("mailers.weekly_report.quiet.never", name: quiet.child.name)
    end
  end
end
