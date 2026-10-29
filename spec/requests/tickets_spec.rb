require "rails_helper"

# Reports and suggested problems as one inbox of tickets: the list and its
# filters, the old addresses that lead to it, a ticket's page, review mode,
# and a suggestion's conversation from the suggester's and their parent's
# side.
describe "The ticket inbox", type: :request do
  let(:admin) { create(:user, role: :admin, name: "Деян") }
  let(:student) { create(:user, name: "Ники Петров", nickname: "niki", elo: 1210) }
  let(:topic) { Topic.create!(name: "Дроби", parent: Topic.create!(name: "Аритметика")) }

  def suggest!(text: "Кое е по-голямо: 5/8 или 3/5?", answer: "5/8", explanation: "5/8 = 25/40, 3/5 = 24/40.", note: nil, user: student)
    suggestion = Suggestion.new(text: text, answer: answer, explanation: explanation, topic_id: topic.id,
                                note: note, suggested_by: user)
    suggestion.save.should be(true)
    suggestion.ticket
  end

  def report!(question = create(:question, text: "Колко е 3/4 от 28?", answer: "12"), user: student, note: nil)
    QuestionReport.file!(question: question, user: user, reason: "wrong_answer", note: note)
  end

  describe "the inbox" do
    it "lists both kinds waiting on us, with counts per state and per kind" do
      reported = report!(note: "отговорът е 21")
      suggested = suggest!(note: "Измислих я в час.")
      talking = report!(create(:question, text: "Периметър на квадрат"), user: create(:user))
      talking.team_reply!(by: admin, body: "Кое точно?")

      sign_in admin
      get "/overseer/inbox"

      response.should have_http_status(:ok)
      response.body.should include("ticket=#{reported.id}")
      response.body.should include("ticket=#{suggested.id}")
      response.body.should_not include("ticket=#{talking.id}")
      response.body.should include(I18n.t("overseer.inbox.kinds_one.suggestion"))
      response.body.should include("#{I18n.t("overseer.inbox.kinds_one.report")} · #{I18n.t("overseer.inbox.reasons.wrong_answer")}")
      response.body.should include(%(<span class="segmented-count">2</span>))
      response.body.should include(%(<span class="segmented-count">1</span>))

      get "/overseer/inbox", params: { kind: "suggestion" }
      response.body.should include("ticket=#{suggested.id}")
      response.body.should_not include("ticket=#{reported.id}")

      get "/overseer/inbox", params: { filter: "talking" }
      response.body.should include("ticket=#{talking.id}")
      response.body.should_not include("ticket=#{reported.id}")
    end

    it "opens the chosen ticket beside the list, in the frame the rows target" do
      reported = report!(note: "отговорът е 21")

      sign_in admin
      get "/overseer/inbox", params: { ticket: reported.id }

      response.body.should match(/<turbo-frame[^>]* id="ticket"/)
      response.body.should include("отговорът е 21")
      response.body.should include(%(data-turbo-frame="ticket"))
      response.body.should include(I18n.t("overseer.inbox.writing_as"))
    end

    it "marks a ticket from the admin's own child and says so above the reply box" do
      child = create(:user, name: "Мая")
      ParentLink.create!(parent: admin, child: child)
      reported = report!(user: child)

      sign_in admin
      get "/overseer/inbox", params: { ticket: reported.id }

      response.body.should include(I18n.t("overseer.inbox.your_child"))
      response.body.should include(ERB::Util.html_escape(I18n.t("overseer.inbox.own_child", name: "Мая")))
    end

    it "answers the old addresses with the inbox and review mode, keeping the filters other pages pass" do
      question = create(:question)
      sign_in admin

      get "/overseer/question_reports", params: { filter: "active", question_id: question.id }
      response.should redirect_to("/overseer/inbox?filter=active&question_id=#{question.id}")

      get "/overseer/reviews"
      response.should redirect_to("/overseer/inbox/review")
    end

    it "gives the nav one waiting count and one per kind" do
      report!
      suggest!

      QuestionReport.waiting_count.should eq(2)
      QuestionReport.waiting_counts_by_kind.should eq("report" => 1, "suggestion" => 1)
    end

    it "keeps students out" do
      sign_in student
      get "/overseer/inbox"
      response.should redirect_to(root_path)

      get "/overseer/inbox/review"
      response.should redirect_to(root_path)
    end
  end

  describe "a ticket's page" do
    it "shows the question as reported beside the current version, with prev/next in the inbox" do
      first = report!(note: "отговорът е 21")
      second = report!(create(:question, text: "Колко е 2 + 2?"), user: create(:user))
      first.question.update!(grading: { "expected" => "21" })

      sign_in admin
      get "/overseer/question_reports/#{first.id}", params: { filter: "waiting" }

      response.should have_http_status(:ok)
      response.body.should include(I18n.t("overseer.inbox.as_seen", name: student.name))
      response.body.should include(I18n.t("overseer.reports.changed_since", fields: I18n.t("report_thread.fields.answer")))
      response.body.should include(I18n.t("overseer.inbox.position", index: 2, total: 2))
      response.body.should include(overseer_question_report_path(second, filter: "waiting"))
      response.body.should include(I18n.t("overseer.inbox.choices.dismissed"))
      response.body.should include(%(name="status"))
    end

    it "shows a suggestion with its checks and the decisions, and comes back where it was pressed" do
      ticket = suggest!

      sign_in admin
      get "/overseer/question_reports/#{ticket.id}"

      response.body.should include(I18n.t("overseer.inbox.suggested_problem"))
      response.body.should include(I18n.t("overseer.inbox.accept"))
      response.body.should include(I18n.t("overseer.inbox.choices_suggestion.resolved"))

      post "/overseer/question_reports/#{ticket.id}/comment", params: { body: "Можеш ли да добавиш защо?", return_to: "/overseer/inbox?ticket=#{ticket.id}" }
      response.should redirect_to("/overseer/inbox?ticket=#{ticket.id}")
      ticket.reload.should be_in_progress
      QuestionReport.awaiting_reply.should eq([ ticket ])
    end

    it "accepts a suggestion from the status choices, publishing it" do
      ticket = suggest!

      sign_in admin
      post "/overseer/question_reports/#{ticket.id}/transition", params: { status: "resolved" }

      ticket.reload.should be_resolved
      ticket.question.should be_published
    end
  end

  describe "review mode" do
    it "shows the oldest waiting suggestion with the author, the checks and the nearest problems" do
      create(:question, text: "Кое е по-голямо: 2/3 или 3/5?", elo: 1100).topics << topic
      older = suggest!(note: "Измислих я в час.")
      suggest!(text: "Колко е 1/2 от 10?", answer: "5", explanation: "Половината от 10 е 5.")

      sign_in admin
      get "/overseer/inbox/review"

      response.should have_http_status(:ok)
      response.body.should include(older.question.body_text.split(":").first)
      response.body.should include("Измислих я в час.")
      response.body.should include(I18n.t("overseer.review.accepted_before", count: 0))
      response.body.should include("Кое е по-голямо: 2/3 или 3/5?")
      response.body.should include(%(data-controller="review-keys"))
      response.body.should include(%(<kbd class="kbd">A</kbd>))
    end

    it "checks the stated answer, the explanation's fractions, the options and duplicates" do
      ticket = suggest!(explanation: "Сравняваме ги.")
      checks = SuggestionChecks.new(ticket.question).checks.to_h { |check| [ check.key, check.state ] }

      checks.should eq(answer_parses: :ok, explanation_skips: :warn, unique: :ok)

      choice = Question.create!(body: RichContent.text_to_doc("Кое е най-голямо?"), answer_type: :multiple_choice, status: :in_review,
                                possible_answers: [ PossibleAnswer.new(value: "9", correct: true, position: 1), PossibleAnswer.new(value: "8", position: 2) ])
      SuggestionChecks.new(choice).checks.map(&:key).should include(:answer_marked, :explanation_missing, :few_options)
    end

    it "suggests a rating from published problems on the same template" do
      [ 1000, 1100, 1300 ].each_with_index { |elo, index| create(:question, text: "Колко е #{index + 2}/4 от 12?", elo: elo) }
      ticket = suggest!(text: "Колко е 3/4 от 28?", answer: "21", explanation: "3/4 от 28: 28 : 4 · 3 = 21.")

      SuggestionChecks.new(ticket.question).same_template.should eq(count: 3, median: 1100)
    end

    it "accepts with the topic and rating set inline, then shows the next one" do
      ticket = suggest!
      waiting = suggest!(text: "Колко е 1/2 от 10?", answer: "5", explanation: "Половината от 10 е 5.")
      other_topic = Topic.create!(name: "Сравняване на дроби", parent: topic.parent)

      sign_in admin
      post "/overseer/question_reports/#{ticket.id}/accept",
           params: { elo: "1120", topic_id: other_topic.id, return_to: "/overseer/inbox/review" }

      response.should redirect_to("/overseer/inbox/review")
      question = ticket.question.reload
      question.should be_published
      question.elo.should eq(1120)
      question.topics.should eq([ other_topic ])
      question.suggested_by.should eq(student)
      ticket.reload.should be_resolved
      ticket.messages.sole.should be_kind_resolved

      follow_redirect!
      response.body.should include("Колко е")
      response.body.should include("ticket=#{waiting.id}")
    end

    it "returns a suggestion only with a note, parking the question" do
      ticket = suggest!

      sign_in admin
      post "/overseer/question_reports/#{ticket.id}/decline", params: { body: " " }
      flash[:alert].should eq(I18n.t("overseer.inbox.decline_needs_note"))
      ticket.reload.should be_open

      post "/overseer/question_reports/#{ticket.id}/decline", params: { body: "Има я вече в друга форма." }
      ticket.reload.should be_dismissed
      ticket.question.reload.should be_private_library
      ticket.messages.sole.body.should eq("Има я вече в друга форма.")
    end

    it "refuses to accept a suggestion that no longer waits" do
      ticket = suggest!
      ticket.decline!(by: admin, body: "Не.")

      sign_in admin
      post "/overseer/question_reports/#{ticket.id}/accept"

      flash[:alert].should eq(I18n.t("overseer.inbox.not_decidable"))
      ticket.question.reload.should be_private_library
    end
  end

  describe "the suggester's side" do
    it "files the suggestion as a ticket with the note, and links it from the suggestions page" do
      sign_in student
      post "/suggestions", params: { suggestion: { text: "Колко е 1/2 + 1/4?", answer: "3/4", topic_id: topic.id, note: "От учебника." } }

      ticket = QuestionReport.sole
      ticket.should be_suggestion
      ticket.should be_open
      ticket.reason.should be_nil
      ticket.note.should eq("От учебника.")
      ticket.snapshot["answer"].should eq("3/4")

      get "/suggestions"
      response.body.should include(report_path(ticket))
    end

    it "shows the conversation worded as a suggestion, with a way to change the problem" do
      ticket = suggest!
      ticket.team_reply!(by: admin, body: "Можеш ли да добавиш защо?")

      sign_in student
      get "/reports"
      response.body.should include(I18n.t("report_thread.suggestion_tag"))

      get "/reports/#{ticket.id}"
      response.should have_http_status(:ok)
      response.body.should include(I18n.t("report_thread.suggested_question"))
      response.body.should include("Можеш ли да добавиш защо?")
      response.body.should include(edit_suggestion_path(ticket.question))
      response.body.should_not include(I18n.t("report_thread.actions.confirmed"))
      response.body.should_not include(I18n.t("report_thread.team") + ": " + admin.name)
    end

    it "tells the suggester about the team's word on „Днес“, worded as a suggestion" do
      ticket = suggest!
      ticket.team_reply!(by: admin, body: "Добави обяснение, моля.")

      sign_in student
      get "/home"
      response.body.should include(I18n.t("report_replies.kickers.suggestions"))
      response.body.should include(I18n.t("report_replies.answer_us_suggestion"))
    end

    it "records the author's change as a new version and puts the ticket back in front of the team" do
      ticket = suggest!(explanation: "")
      ticket.team_reply!(by: admin, body: "Добави обяснение.")

      sign_in student
      get "/suggestions/#{ticket.question_id}/edit"
      response.should have_http_status(:ok)
      response.body.should include("Кое е по-голямо: 5/8 или 3/5?")

      patch "/suggestions/#{ticket.question_id}", params: { suggestion: {
        text: "Кое е по-голямо: 5/8 или 3/5?", answer: "5/8", topic_id: topic.id,
        explanation: "5/8 = 25/40, а 3/5 = 24/40."
      } }

      response.should redirect_to(report_path(ticket))
      ticket.reload.messages.last.should be_kind_edited
      ticket.version.should eq(2)
      ticket.changes_since_report.should eq([ "explanation" ])
      QuestionReport.awaiting_team.should eq([ ticket ])

      get "/reports/#{ticket.id}"
      response.body.should include(I18n.t("report_thread.events.edited", version: 2))
    end

    it "lets nobody but the author change a suggestion, and nobody once it is decided" do
      ticket = suggest!

      sign_in create(:user)
      get "/suggestions/#{ticket.question_id}/edit"
      response.should have_http_status(:not_found)

      ticket.accept!(by: admin)
      sign_in student
      get "/suggestions/#{ticket.question_id}/edit"
      response.should have_http_status(:not_found)
    end

    it "shows a parent the child's suggestion under „Сигнали“, worded as one" do
      parent = create(:user, role: :parent, verified_at: Time.current)
      ParentLink.create!(parent: parent, child: student)
      ticket = suggest!

      sign_in parent
      get "/parents/children/#{student.id}", params: { tab: "reports" }
      response.body.should include(I18n.t("report_thread.suggestion"))

      get "/parents/children/#{student.id}/reports/#{ticket.id}"
      response.body.should include(I18n.t("parents.reports.suggestion_title", name: student.name))
    end
  end

  describe "email about a suggestion" do
    let(:parent) { create(:user, role: :parent, email: "mama@example.com", verified_at: Time.current) }

    before do
      allow(Mailing).to receive(:enabled?).and_return(true)
      ParentLink.create!(parent: parent, child: student)
      ActionMailer::Base.deliveries.clear
    end

    it "does not tell the parents a suggestion was filed — it is not a problem with anything" do
      perform_enqueued_jobs { suggest! }

      ActionMailer::Base.deliveries.should be_empty
    end

    it "tells them the team wrote about it, in a suggestion's words" do
      ticket = suggest!
      perform_enqueued_jobs { ticket.team_reply!(by: admin, body: "Можеш ли да добавиш защо?") }

      mail = ActionMailer::Base.deliveries.sole
      mail.to.should eq([ "mama@example.com" ])
      mail.subject.should eq(I18n.t("mailers.suggestion_activity.family_subject", what: I18n.t("mailers.suggestion_activity.subjects.comment")))
    end
  end
end
