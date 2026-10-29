require "rails_helper"
require Rails.root.join("db/migrate/20261030100000_add_kind_to_question_reports")

describe QuestionReport do
  let(:admin) { create(:user, role: :admin) }
  let(:suggester) { create(:user) }

  def suggested(status: :in_review, text: "Колко е 1/2 + 1/4?")
    create(:question, text: text, answer: "3/4", status: status, suggested_by: suggester)
  end

  describe "kind" do
    it "makes every report a report, needing a reason, and lets a suggestion have none" do
      question = create(:question)
      QuestionReport.new(question: question, user: suggester).should_not be_valid
      QuestionReport.new(question: question, user: suggester, reason: :typo).should be_report

      QuestionReport.new(question: question, user: suggester, kind: :suggestion).should be_valid
    end

    it "files a suggestion open, with version 1 kept as its snapshot" do
      question = suggested
      ticket = QuestionReport.file_suggestion!(question: question, user: suggester, note: "  От учебника. ")

      ticket.should be_suggestion
      ticket.should be_open
      ticket.should be_awaiting_team
      ticket.note.should eq("От учебника.")
      ticket.snapshot.should eq(QuestionReport.snapshot_of(question))
      ticket.version.should eq(1)
      ticket.student_kinds.should eq(%w[comment])
    end

    it "lets the suggester's report of their own problem go into its conversation" do
      question = suggested(status: :published)
      ticket = QuestionReport.file_suggestion!(question: question, user: suggester)

      QuestionReport.file!(question: question, user: suggester, reason: "typo", note: "Има печатна грешка")

      QuestionReport.sole.should eq(ticket)
      ticket.reload.should be_suggestion
      ticket.messages.sole.body.should include("Има печатна грешка")
    end
  end

  describe "deciding a suggestion" do
    let(:ticket) { QuestionReport.file_suggestion!(question: suggested, user: suggester) }

    it "accepts it: publishes the question and closes the ticket resolved" do
      ticket.accept!(by: admin, body: "Благодарим!", elo: 1120)

      ticket.question.reload.should be_published
      ticket.question.elo.should eq(1120)
      ticket.should be_resolved
      ticket.resolver.should eq(admin)
      ticket.messages.sole.should have_attributes(kind: "resolved", body: "Благодарим!")
      ticket.should_not be_decidable
    end

    it "returns it: parks the question and closes the ticket dismissed" do
      ticket.decline!(by: admin, body: "Вече я има.")

      ticket.question.reload.should be_private_library
      ticket.should be_dismissed
      ticket.messages.sole.should have_attributes(kind: "dismissed", body: "Вече я има.")
    end

    it "asking the author is a comment that waits on them, and their answer puts it back in front of us" do
      ticket.team_reply!(by: admin, body: "Защо?")
      QuestionReport.awaiting_reply.should eq([ ticket ])
      QuestionReport.awaiting_team.should be_empty

      ticket.author_edited!
      ticket.version.should eq(2)
      QuestionReport.awaiting_team.should eq([ ticket ])
      QuestionReport.awaiting_reply.should be_empty
    end
  end

  describe "the backfill of suggestions made before tickets" do
    def backfill
      migration = AddKindToQuestionReports.new
      migration.verbose = false
      migration.backfill
    end

    it "gives every suggestion a ticket, its status read off the question" do
      waiting = suggested(text: "Чака")
      accepted = suggested(status: :published, text: "Приета")
      retired = suggested(status: :retired, text: "Архивирана")
      parked = suggested(status: :private_library, text: "Върната")
      drafted = suggested(status: :draft, text: "Скрита")
      create(:question, text: "Ничия")

      backfill

      tickets = QuestionReport.suggestion.index_by(&:question)
      tickets.keys.should contain_exactly(waiting, accepted, retired, parked, drafted)
      tickets.values.map(&:user).uniq.should eq([ suggester ])
      tickets[waiting].should be_open
      tickets[waiting].messages.should be_empty
      tickets[waiting].snapshot["answer"].should eq("3/4")
      [ accepted, retired ].each { |question| tickets[question].should be_resolved }
      [ parked, drafted ].each { |question| tickets[question].should be_dismissed }
      tickets[accepted].messages.sole.should be_kind_resolved
      tickets[accepted].should_not be_unread
      tickets.values.map(&:reason).uniq.should eq([ nil ])
    end

    it "leaves a suggester's own report of the question as it is, and runs twice without doubling" do
      question = suggested(status: :published)
      report = QuestionReport.file!(question: question, user: suggester, reason: "typo")

      backfill
      backfill

      QuestionReport.sole.should eq(report)
      report.reload.should be_report
    end
  end
end
