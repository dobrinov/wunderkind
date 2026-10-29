require "rails_helper"

describe UserMailer do
  describe "#report_activity" do
    let(:student) { create(:user, name: "Ели", verified_at: Time.current) }
    let(:admin) { create(:user, role: :admin, name: "Админ Админов") }
    let(:question) { create(:question, text: "Колко е 2 + 3?", answer: "5") }
    let(:report) { QuestionReport.file!(question: question, user: student, reason: "wrong_answer") }

    it "tells the student what the team wrote, and links to the conversation" do
      report.team_close!(:resolved, by: admin, body: "Поправихме отговора.")
      mail = UserMailer.report_activity(report.messages.last, student)

      mail.to.should eq([ student.email ])
      mail.subject.should eq(I18n.t("mailers.report_activity.subjects.resolved"))
      [ mail.html_part.decoded, mail.text_part.decoded ].each do |body|
        body.should include("Колко е 2 + 3?", "Поправихме отговора.", "/reports/#{report.id}")
        body.should_not include("Админ Админов")
      end
    end

    it "tells a parent that it was their child who reported the question" do
      parent = create(:user, role: :parent, name: "Мама", verified_at: Time.current)
      ParentLink.create!(parent: parent, child: student)
      report.team_reply!(by: admin, body: "Погледнахме я.")
      mail = UserMailer.report_activity(report.messages.last, parent)

      mail.to.should eq([ parent.email ])
      mail.subject.should include(I18n.t("mailers.report_activity.subjects.comment"))
      [ mail.html_part.decoded, mail.text_part.decoded ].each do |body|
        body.should include("Здравей, Мама!", "Ели ни съобщи за проблем със задача", "Погледнахме я.")
        body.should include("/parents/children/#{student.id}/reports/#{report.id}")
      end
    end

    it "carries a one-click unsubscribe for this email alone" do
      report.team_reply!(by: admin, body: "Погледнахме.")
      mail = UserMailer.report_activity(report.messages.last, student)
      url = mail["List-Unsubscribe"].value[/<(.+)>/, 1]

      mail["List-Unsubscribe-Post"].value.should eq("List-Unsubscribe=One-Click")
      URI(url).path.should match(%r{\A/emails/[^/]+/unsubscribe/report_activity\z})
    end
  end
end
