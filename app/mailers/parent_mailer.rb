class ParentMailer < ApplicationMailer
  # See WeeklyReport. Built here from the week rather than handed a report, so
  # the mail can be queued and still say what the week said when it is sent.
  def weekly_report(parent, week_start)
    @parent = parent
    @report = WeeklyReport.new(parent, week_start: week_start)
    @unsubscribe_url = weekly_report_unsubscribe_url(parent.generate_token_for(:weekly_report_unsubscribe))

    # One-click unsubscribe (RFC 8058): the large providers show their own
    # button for it and expect it of anything sent weekly.
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    I18n.with_locale(parent.locale.presence || I18n.default_locale) do
      mail to: parent.email,
           subject: t("mailers.weekly_report.subject",
                      names: @report.children.map { |entry| entry.child.name }.to_sentence,
                      dates: @report.dates_label)
    end
  end
end
