# A sign-in that happened, written by User#logged_in! and read by day on
# /overseer/stats (AdminStats#account_days). Never edited, so it has no
# updated_at.
#
# Sessions here last until somebody signs out, so this is not „who came
# today" — a child whose tablet stays signed in practises for weeks on one
# row. That is the active-students headline's; this is how often people have
# to get back in.
class SignIn < ApplicationRecord
  # password — the sign-in form; signup — the session a new account starts
  # with; email_verification — the first use of the verification link;
  # switch — a parent opening a managed child's profile, the only sign-in
  # such a child has.
  VIAS = %w[password signup email_verification switch].freeze

  belongs_to :user

  validates :via, inclusion: { in: VIAS }
end
