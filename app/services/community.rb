# The Discord server: a place for parents, teachers and older students to
# talk, ask for help and share ideas.
#
# Discord is 13+ by its own terms and Bulgaria's age of digital consent is 14,
# while most of the people practising here are younger — so the link is
# offered to grown-ups only, never to a student, the same stance the app takes
# on children meeting strangers (friend codes, nicknames, no search by name).
#
# The invite is read from the environment (DISCORD_INVITE_URL in
# /opt/apps/wunderkind/.env) rather than kept here, so the link appears and
# moves without a release, and with nothing set nothing is shown.
module Community
  def self.discord_url
    ENV["DISCORD_INVITE_URL"].presence
  end

  def self.offered_to?(user)
    discord_url.present? && user.present? && !user.student?
  end
end
