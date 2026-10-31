namespace :reports do
  # The parents' weekly email. Run by cron on the host every Sunday at 18:00
  # (see CLAUDE.md, Deployment), when it reports the week ending that day; run
  # on any other day it makes up the last full week. Safe to run again — a
  # parent already sent that week's is not a recipient.
  desc "Email each parent last week's report on their children (skips quiet weeks)"
  task weekly: :environment do
    abort "Mail is not configured (SMTP_ADDRESS); nothing sent." unless Mailing.enabled?

    week_start = WeeklyReport.week_start_for
    sent = quiet = failed = 0
    WeeklyReport.recipients(week_start).find_each do |parent|
      WeeklyReport.deliver(parent, week_start: week_start) ? sent += 1 : quiet += 1
    rescue StandardError => error
      # One bad address must not stop everyone else's report.
      failed += 1
      Rails.error.report(error, handled: true, source: "weekly_report", context: { parent_id: parent.id })
      warn "Parent #{parent.id}: #{error.class}: #{error.message}"
    end
    puts "Weekly report for #{week_start}: #{sent} sent, #{quiet} quiet, #{failed} failed."
  end
end
