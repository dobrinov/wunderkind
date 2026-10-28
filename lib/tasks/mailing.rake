namespace :mailing do
  # Run once, the day SMTP is first configured in production.
  #
  # While mail was off, User#verified? answered true for everyone, so every
  # account was in use without ever confirming its address. Turning mail on
  # makes the column count, and every one of those parents would suddenly be
  # refused at `require_verified_email` — locked out of their own children's
  # goals for want of an email they were never sent. They have been signing in
  # with that address for months, which is the thing a confirmation proves, so
  # they are stamped as confirmed. Accounts made after this run confirm the
  # ordinary way, and only confirmed addresses get the weekly report (see
  # WeeklyReport), so mail about a child never goes to an address nobody has
  # shown is theirs.
  desc "Mark every existing account with an email as verified (once, when mail goes live)"
  task grandfather: :environment do
    count = User.where(verified_at: nil).where.not(email: nil).update_all(verified_at: Time.current)
    puts "Marked #{count} existing accounts as verified."
  end
end
