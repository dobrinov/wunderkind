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
  Kind = Data.define(:key, :roles)

  KINDS = [
    Kind.new(key: :weekly_report, roles: %w[parent])
  ].freeze

  # What this person can be sent, so what they are offered a switch for. A
  # managed child has no address, so nothing.
  def self.for(user)
    return [] if user.email.blank?

    KINDS.select { |kind| kind.roles.include?(user.role) }
  end

  def self.find(key)
    KINDS.find { |kind| kind.key.to_s == key.to_s }
  end
end
