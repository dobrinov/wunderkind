namespace :reports do
  # The parents' weekly email, for the week that ended last Sunday. Run by cron
  # on the host every Monday morning (see CLAUDE.md, Deployment); safe to run
  # again — a parent already sent this week's is not a recipient.
  desc "Email each parent last week's report on their children (skips quiet weeks)"
  task weekly: :environment do
    abort "Mail is not configured (SMTP_ADDRESS); nothing sent." unless Mailing.enabled?

    week_start = WeeklyReport.last_week_start
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
