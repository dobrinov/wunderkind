# The emails a person may switch off, and who each one is for. Each kind is a
# boolean column of the same name on users, default on. The account emails
# (confirming an address, resetting a password) are not here on purpose: they
# are only ever sent because the person just asked for them, and switching
# them off would only lock somebody out.
#
# A new optional email is one entry here, its column, and its copy under
# `email_preferences.kinds` — Настройки, the page linked from every email and
# the one-click unsubscribe all read this list.
module EmailPreferences
  # `audience` says whether the email is for this person: for a parent
  # by role, or anybody — an admin too — with a child linked to them.
  Kind = Data.define(:key, :audience)

  WITH_CHILDREN = ->(user) { user.parent? || user.children.exists? }

  KINDS = [
    Kind.new(key: :weekly_report, audience: WITH_CHILDREN),
    # The team's activity on a question a student reported
    # (QuestionReportMessage#email_recipients) — to the student, and to their
    # parents, who can follow the conversation and write in it. A managed
    # child has no address; their parents are the ones emailed.
    Kind.new(key: :report_activity, audience: ->(user) { user.student? || WITH_CHILDREN.(user) })
  ].freeze

  # What this person can be sent, so what they are offered a switch for. A
  # managed child has no address, so nothing.
  def self.for(user)
    return [] if user.email.blank?

    KINDS.select { |kind| kind.audience.(user) }
  end

  def self.find(key)
    KINDS.find { |kind| kind.key.to_s == key.to_s }
  end
end
