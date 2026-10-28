require "rails_helper"

describe ParentMailer do
  let(:parent) { create(:user, role: :parent, name: "Мама", verified_at: Time.current) }
  let(:child) { User.create_managed_child!(parent:, name: "Ани", birth_year: 2018) }
  let(:week_start) { Date.new(2026, 10, 19) }

  around { |example| travel_to(Time.zone.local(2026, 10, 26, 7)) { example.run } }

  before do
    assignment = Assignment.create!(user: child)
    3.times do |index|
      row = assignment.assignment_questions.create!(question: create(:question, answer: "5"), position: index + 1)
      UserAnswer.create!(user: child, assignment_question: row, value: "5", correct: index < 2,
                         response: { "value" => "5" }, created_at: Time.zone.local(2026, 10, 21, 12))
    end
  end

  it "says how the child's week went, in both parts" do
    mail = ParentMailer.weekly_report(parent, week_start)

    mail.to.should eq([ parent.email ])
    mail.subject.should eq("Ани: седмицата в Wunderkind (19–25 октомври)")
    [ mail.html_part.decoded, mail.text_part.decoded ].each do |body|
      body.should include("Ани", "67%", "задачи", "≈ 2 клас")
      body.should include("/parents/children/#{child.id}")
    end
  end

  it "carries a one-click unsubscribe that works without signing in" do
    mail = ParentMailer.weekly_report(parent, week_start)
    url = mail["List-Unsubscribe"].value[/<(.+)>/, 1]

    mail["List-Unsubscribe-Post"].value.should eq("List-Unsubscribe=One-Click")
    mail.html_part.decoded.should include(url)
    URI(url).path.should match(%r{\A/emails/[^/]+/unsubscribe/weekly_report\z})
    # …and a way to every email setting, from the same link.
    mail.html_part.decoded.should include(URI(url).path.delete_suffix("/unsubscribe/weekly_report"))
  end
end
