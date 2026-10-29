# Who said what in a report's conversation, as each reader should see it. The
# student sees „Ти" for themself and „Екипът на Wunderkind" for whoever on the
# team wrote — never which admin; a parent sees „Ти" for their own messages
# and the child by name; the team sees everybody by name. A parent is marked
# as one everywhere, since a conversation with a child is read differently
# once an adult has joined it.
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
end
