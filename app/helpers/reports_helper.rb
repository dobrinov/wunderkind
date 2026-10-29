# Who said what in a ticket's conversation, as each reader should see it. The
# student sees „Ти" for themself and „Екипът на Wunderkind" for whoever on the
# team wrote — never which admin; a parent sees „Ти" for their own messages
# and the child by name; the team sees everybody by name. A parent is marked
# as one everywhere, since a conversation with a child is read differently
# once an adult has joined it.
#
# A ticket is a report or a suggested problem, and the two are worded apart
# wherever a reader meets them: a suggestion is „Предложение", has no reason,
# and is accepted or returned rather than fixed or found correct.
module ReportsHelper
  # viewer: :student, :family or :team
  def report_message_author(message, viewer)
    if message.from_reporter?
      viewer == :student ? t("report_thread.you") : message.question_report.user.name
    elsif message.from_family?
      return t("report_thread.you") if viewer == :family && message.author_id == current_user.id

      t("report_thread.parent", name: message.author&.name || t("report_thread.parent_unknown"))
    else
      viewer == :team ? (message.author&.name || t("report_thread.team")) : t("report_thread.team")
    end
  end

  # Whether the message sits on the reader's own side of the thread.
  def report_message_mine?(message, viewer)
    case viewer
    when :student then message.from_reporter?
    when :family then message.from_family? && message.author_id == current_user.id
    else message.from_team?
    end
  end

  # What a change of state in the thread says. An author's edit names the
  # version it made.
  def report_event_label(message)
    report = message.question_report
    if message.kind_edited?
      version = 1 + report.messages.take_while { |each| each != message }.count(&:kind_edited?) + 1
      return t("report_thread.events.edited", version: version)
    end

    key = report.suggestion? ? "report_thread.suggestion_events.#{message.kind}" : nil
    key && I18n.exists?(key) ? t(key) : t("report_thread.events.#{message.kind}")
  end

  def ticket_status_label(report)
    t(report.suggestion? ? "report_thread.suggestion_statuses.#{report.status}" : "report_thread.statuses.#{report.status}")
  end

  # „⚑ Верният отговор е грешен" for a report, „Предложена задача" for a
  # suggestion — the line under a ticket's status.
  def ticket_subject(report)
    report.suggestion? ? t("report_thread.suggestion") : "⚑ #{t("reports.reasons.#{report.reason}")}"
  end

  # The inbox's tag: kind, and the reason of a report.
  def ticket_tag(report)
    return t("overseer.inbox.kinds_one.suggestion") if report.suggestion?

    "#{t("overseer.inbox.kinds_one.report")} · #{t("overseer.inbox.reasons.#{report.reason}")}"
  end

  # Where the conversation stands, from the team's chair: new, the other side
  # wrote last, or we did and wait.
  def ticket_turn(report)
    last = report.messages.last
    return t("overseer.inbox.turn.closed", status: ticket_status_label(report)) if report.closed?
    return t("overseer.inbox.turn.new") if last.nil?
    return t("overseer.inbox.turn.edited") if last.kind_edited?
    return t("overseer.inbox.turn.ours") if last.from_team?

    report.messages.any?(&:from_team?) ? t("overseer.inbox.turn.answered") : t("overseer.inbox.turn.theirs")
  end

  # How long ago, the way an inbox says it: minutes, hours, „вчера", a
  # weekday within the week, then a date.
  def ticket_age(time)
    seconds = Time.current - time
    if seconds < 1.hour then t("overseer.inbox.age.minutes", count: [ (seconds / 60).floor, 1 ].max)
    elsif time.to_date == Date.current then t("overseer.inbox.age.hours", count: (seconds / 3600).floor)
    elsif time.to_date == Date.yesterday then t("overseer.inbox.age.yesterday")
    elsif time > 6.days.ago then l(time, format: "%a")
    else l(time.to_date, format: :short)
    end
  end

  # The person behind a ticket for the team: nickname first, and their role.
  def ticket_person(user)
    user.nickname.presence || user.name
  end
end
