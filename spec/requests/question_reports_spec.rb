require "rails_helper"

describe "Reporting a problem with a question", type: :request do
  let(:student) { create(:user, elo: 1200) }
  let(:admin) { create(:user, role: :admin) }

  def assignment_with(count)
    assignment = Assignment.create!(user: student)
    count.times { |index| assignment.assignment_questions.create!(question: create(:question, answer: "5"), position: index + 1) }
    assignment
  end

  it "offers the report control on the question" do
    assignment_question = assignment_with(1).assignment_questions.first

    sign_in student
    get "/questions/#{assignment_question.id}"

    response.should have_http_status(:ok)
    response.body.should include(question_report_path(assignment_question))
    response.body.should include(I18n.t("reports.trigger"))
    response.body.should include(I18n.t("reports.reasons.misleading"))
    response.body.should include(I18n.t("reports.reasons.missing_answer"))
  end

  it "offers the report control when reviewing a past answer" do
    assignment = assignment_with(1)
    assignment_question = assignment.assignment_questions.first

    sign_in student
    post "/questions/#{assignment_question.id}/answer", params: { value: "5" }
    get "/questions/#{assignment_question.id}/answer"

    response.should have_http_status(:ok)
    response.body.should include(question_report_path(assignment_question))
  end

  it "records the report and comes back to the question" do
    assignment_question = assignment_with(1).assignment_questions.first

    sign_in student
    post "/questions/#{assignment_question.id}/report",
         params: { reason: "missing_answer", note: "  Няма 12 сред отговорите  ", return_to: "/questions/#{assignment_question.id}" }

    response.should redirect_to(question_path(assignment_question))
    report = QuestionReport.sole
    report.question.should eq(assignment_question.question)
    report.user.should eq(student)
    report.should be_missing_answer
    report.should be_open
    report.note.should eq("Няма 12 сред отговорите")
  end

  it "leaves the answer, the rating and the XP alone" do
    assignment_question = assignment_with(1).assignment_questions.first
    elo_before = assignment_question.question.elo

    sign_in student
    post "/questions/#{assignment_question.id}/report", params: { reason: "broken" }

    assignment_question.reload.user_answer.should be_nil
    assignment_question.question.reload.elo.should eq(elo_before)
    student.reload.total_xp.should be_zero
    student.elo.should eq(1200)
  end

  it "replaces the student's earlier report rather than piling up a second one" do
    assignment_question = assignment_with(1).assignment_questions.first

    sign_in student
    post "/questions/#{assignment_question.id}/report", params: { reason: "typo" }
    post "/questions/#{assignment_question.id}/report", params: { reason: "wrong_answer", note: "5 не е вярно" }

    QuestionReport.count.should eq(1)
    QuestionReport.sole.should be_wrong_answer
  end

  it "shows what was reported instead of a second form" do
    assignment_question = assignment_with(1).assignment_questions.first

    sign_in student
    post "/questions/#{assignment_question.id}/report", params: { reason: "image" }
    get "/questions/#{assignment_question.id}"

    response.body.should include(I18n.t("reports.filed", reason: I18n.t("reports.reasons.image").downcase))
    response.body.should_not include(I18n.t("reports.lede"))
  end

  it "refuses a report without a reason" do
    assignment_question = assignment_with(1).assignment_questions.first

    sign_in student
    post "/questions/#{assignment_question.id}/report", params: { reason: "" }

    response.should redirect_to(question_path(assignment_question))
    flash[:alert].should eq(I18n.t("reports.no_reason"))
    QuestionReport.count.should be_zero
  end

  it "refuses to report from another student's assignment" do
    assignment_question = assignment_with(1).assignment_questions.first

    sign_in create(:user)
    post "/questions/#{assignment_question.id}/report", params: { reason: "typo" }

    response.should have_http_status(:not_found)
    QuestionReport.count.should be_zero
  end

  it "ignores an off-site return_to" do
    assignment_question = assignment_with(1).assignment_questions.first

    sign_in student
    post "/questions/#{assignment_question.id}/report",
         params: { reason: "typo", return_to: "https://example.com/phish" }

    response.should redirect_to(question_path(assignment_question))
  end

  describe "from a duel" do
    let!(:questions) { create_list(:question, Challenge::QUESTION_COUNT, elo: 1050, answer: "42") }
    let(:opponent) { create(:user) }

    def matched_duel
      duel_between(student, opponent)
    end

    it "offers the control on the problem in front of the player" do
      challenge = matched_duel

      sign_in student
      get "/challenges/#{challenge.id}"

      response.should have_http_status(:ok)
      response.body.should include(challenge_reports_path(challenge))
      response.body.should include(I18n.t("reports.trigger"))
      response.body.should include(I18n.t("reports.clock_note"))
    end

    it "records the report and puts the player back on the same problem" do
      challenge = matched_duel

      sign_in student
      get "/challenges/#{challenge.id}"
      challenge_question = challenge.challenge_questions.first
      started_at = challenge.participant_for(student).reload.question_started_at

      post "/challenges/#{challenge.id}/reports",
           params: { challenge_question_id: challenge_question.id, reason: "misleading",
                     return_to: "/challenges/#{challenge.id}" }

      response.should redirect_to(challenge_path(challenge))
      QuestionReport.sole.question.should eq(challenge_question.question)
      QuestionReport.sole.should be_misleading

      # The problem is served again on the way back, which must not hand the
      # reporter a fresh speed window.
      follow_redirect!
      challenge.participant_for(student).reload.question_started_at.should eq(started_at)
    end

    it "pays nothing, answers nothing and stops no clock" do
      challenge = matched_duel

      sign_in student
      get "/challenges/#{challenge.id}"
      post "/challenges/#{challenge.id}/reports",
           params: { challenge_question_id: challenge.challenge_questions.first.id, reason: "broken" }

      participant = challenge.participant_for(student).reload
      participant.score.should be_zero
      participant.challenge_answers.should be_empty
      student.reload.total_xp.should be_zero
      challenge.reload.should be_active
    end

    it "offers a picker over the whole match on the result screen" do
      challenge = matched_duel
      QuestionReport.file!(question: challenge.challenge_questions.first.question, user: student, reason: "typo")
      challenge.update!(status: :finished, winner: opponent)

      sign_in student
      get "/challenges/#{challenge.id}"

      response.should have_http_status(:ok)
      response.body.should include(I18n.t("reports.trigger_duel"))
      response.body.should include(I18n.t("reports.which_problem"))
      # Every problem of the match is pickable, and the one already reported is
      # marked as such.
      challenge.challenge_questions.each do |challenge_question|
        response.body.should include("value=\"#{challenge_question.id}\"")
      end
      response.body.should include("⚑ 1.")
    end

    it "takes a report from the result screen" do
      challenge = matched_duel
      challenge.update!(status: :finished, winner: opponent)
      challenge_question = challenge.challenge_questions.third

      sign_in student
      post "/challenges/#{challenge.id}/reports",
           params: { challenge_question_id: challenge_question.id, reason: "wrong_answer", note: "42 не е вярно" }

      response.should redirect_to(challenge_path(challenge))
      QuestionReport.sole.question.should eq(challenge_question.question)
      QuestionReport.sole.note.should eq("42 не е вярно")
    end

    it "refuses a report on a duel the student did not play" do
      challenge = matched_duel

      sign_in create(:user)
      post "/challenges/#{challenge.id}/reports",
           params: { challenge_question_id: challenge.challenge_questions.first.id, reason: "typo" }

      response.should have_http_status(:not_found)
      QuestionReport.count.should be_zero
    end

    it "refuses a problem from another match" do
      challenge = matched_duel
      other = create(:question, answer: "42")
      foreign = Challenge.create!(question_count: 1, seconds_per_question: 30, target_elo: 1050).
        challenge_questions.create!(question: other, position: 1)

      sign_in student
      post "/challenges/#{challenge.id}/reports",
           params: { challenge_question_id: foreign.id, reason: "typo" }

      response.should have_http_status(:not_found)
      QuestionReport.count.should be_zero
    end

    it "refuses a duel report without a reason" do
      challenge = matched_duel

      sign_in student
      post "/challenges/#{challenge.id}/reports",
           params: { challenge_question_id: challenge.challenge_questions.first.id, reason: "" }

      flash[:alert].should eq(I18n.t("reports.no_reason"))
      QuestionReport.count.should be_zero
    end
  end

  describe "the admin queue" do
    let(:question) { create(:question, answer: "5") }

    def report!(reason: "wrong_answer", note: nil, user: student)
      QuestionReport.file!(question: question, user: user, reason: reason, note: note)
    end

    it "lists the reports waiting on the team, one row per report" do
      report!(note: "Верният отговор е 6")
      other = report!(user: create(:user))
      other.team_reply!(by: admin, body: "Погледнахме.")

      sign_in admin
      get "/overseer/question_reports"

      response.should have_http_status(:ok)
      response.body.should include("Верният отговор е 6")
      response.body.should include(I18n.t("overseer.reports.awaiting"))
      response.body.should_not include(overseer_question_report_path(other))

      get "/overseer/question_reports", params: { filter: "active" }
      response.body.should include(overseer_question_report_path(other))
    end

    it "lists closed reports under their own filter, and one question's reports" do
      closed = report!
      closed.team_close!(:dismissed, by: admin, body: "Вярна е.")
      elsewhere = QuestionReport.file!(question: create(:question), user: student, reason: "typo")

      sign_in admin
      get "/overseer/question_reports", params: { filter: "closed" }
      response.body.should include(overseer_question_report_path(closed))

      get "/overseer/question_reports", params: { filter: "all", question_id: question.id }
      response.body.should include(overseer_question_report_path(closed))
      response.body.should_not include(overseer_question_report_path(elsewhere))
    end

    it "counts the reports waiting on the team in the admin nav" do
      report!
      report!(user: create(:user))

      sign_in admin
      get "/overseer/questions"

      response.body.should include(I18n.t("overseer.nav.inbox"), %(<span class="nav-count">2</span>))
      response.body.should include("⚑ 2")
    end

    it "opens a report as a ticket with the question, the complaint and the status dropdown" do
      report = report!(note: "Верният отговор е 6")
      report!(user: create(:user, name: "Бобо"))

      sign_in admin
      get "/overseer/question_reports/#{report.id}"

      response.should have_http_status(:ok)
      response.body.should include(question.body_text)
      response.body.should include("Верният отговор е 6")
      response.body.should include(%(name="status"))
      response.body.should include(I18n.t("overseer.reports.resolved_version"))
      response.body.should include(I18n.t("overseer.reports.dismiss_reason"))
      response.body.should include("Бобо")
      response.body.should include(I18n.t("overseer.reports.apply_to_related", count: 1))
    end

    it "comments on one report and puts it in progress" do
      report = report!
      other = report!(user: create(:user))

      sign_in admin
      post "/overseer/question_reports/#{report.id}/comment", params: { body: "Прочети пак: пита се за периметъра." }

      response.should redirect_to(overseer_question_report_path(report))
      report.reload.should be_in_progress
      report.messages.sole.body.should eq("Прочети пак: пита се за периметъра.")
      other.reload.should be_open
      QuestionReport.awaiting_team.should eq([ other ])
    end

    it "comments on the linked reports too when asked" do
      report = report!
      other = report!(user: create(:user))

      sign_in admin
      post "/overseer/question_reports/#{report.id}/comment", params: { body: "Поправихме отговора.", apply_to_related: "1" }

      [ report, other ].each { |each_report| each_report.reload.should be_in_progress }
    end

    it "refuses an empty comment" do
      report = report!

      sign_in admin
      post "/overseer/question_reports/#{report.id}/comment", params: { body: " " }

      flash[:alert].should eq(I18n.t("overseer.reports.reply_empty"))
      report.reload.should be_open
    end

    it "marks a report in progress from the dropdown" do
      report = report!

      sign_in admin
      post "/overseer/question_reports/#{report.id}/transition", params: { status: "in_progress" }

      report.reload.should be_in_progress
      report.messages.sole.should be_kind_started
    end

    it "resolves only with the fixed version, which is the question itself when it was edited" do
      report = report!

      sign_in admin
      post "/overseer/question_reports/#{report.id}/transition", params: { status: "resolved", corrected_question: "" }
      flash[:alert].should eq(I18n.t("overseer.reports.resolve_needs_version"))
      report.reload.should be_open

      post "/overseer/question_reports/#{report.id}/transition",
           params: { status: "resolved", corrected_question: question.id.to_s, body: "Поправихме отговора на 6." }
      report.reload.should be_resolved
      report.resolver.should eq(admin)
      report.messages.sole.corrected_question.should eq(question)
      report.should_not be_replaced
    end

    it "carries no message with a status change other than „not a problem“ — that is what comments are for" do
      report = report!

      sign_in admin
      post "/overseer/question_reports/#{report.id}/transition",
           params: { status: "resolved", corrected_question: question.id.to_s, body: "Остана от друго поле." }

      report.reload.should be_resolved
      report.messages.sole.body.should be_nil

      get "/overseer/question_reports/#{report.id}"
      response.body.should_not include("Съобщение до ученика")
    end

    it "resolves pointing at a different question" do
      report = report!
      corrected = create(:question, text: "Колко е 2 + 4?", answer: "6")

      sign_in admin
      post "/overseer/question_reports/#{report.id}/transition",
           params: { status: "resolved", corrected_question: "https://wunderkind.bg/overseer/questions/#{corrected.id}/edit" }

      report.reload.should be_resolved
      report.current_question.should eq(corrected)
    end

    it "refuses a corrected version that does not exist" do
      report = report!

      sign_in admin
      post "/overseer/question_reports/#{report.id}/transition", params: { status: "resolved", corrected_question: "999999999" }

      flash[:alert].should eq(I18n.t("overseer.reports.corrected_unknown"))
      report.reload.should be_open
    end

    it "dismisses only with an explanation, without touching the question" do
      report = report!

      sign_in admin
      post "/overseer/question_reports/#{report.id}/transition", params: { status: "dismissed", body: " " }
      flash[:alert].should eq(I18n.t("overseer.reports.dismiss_needs_reason"))
      report.reload.should be_open

      post "/overseer/question_reports/#{report.id}/transition", params: { status: "dismissed", body: "5 е вярно: 2 + 3 = 5." }
      report.reload.should be_dismissed
      report.messages.sole.body.should eq("5 е вярно: 2 + 3 = 5.")
      question.reload.should be_published
    end

    it "closes the linked reports too when asked" do
      report = report!
      other = report!(user: create(:user))

      sign_in admin
      post "/overseer/question_reports/#{report.id}/transition",
           params: { status: "resolved", corrected_question: question.id.to_s, apply_to_related: "1" }

      [ report, other ].each { |each_report| each_report.reload.should be_resolved }
    end

    it "reopens a closed report from the dropdown" do
      report = report!
      report.team_close!(:dismissed, by: admin, body: "Вярна е.")

      sign_in admin
      post "/overseer/question_reports/#{report.id}/transition", params: { status: "in_progress", body: "Всъщност има грешка." }

      report.reload.should be_in_progress
      report.messages.last.should be_kind_reopened
    end

    it "refuses a status that is not on the dropdown" do
      report = report!

      sign_in admin
      post "/overseer/question_reports/#{report.id}/transition", params: { status: "open" }

      flash[:alert].should eq(I18n.t("overseer.reports.unknown_status"))
    end

    it "takes a broken question out of circulation and keeps every report on it in progress" do
      report = report!
      other = report!(user: create(:user))

      sign_in admin
      post "/overseer/question_reports/#{report.id}/withdraw"

      question.reload.should be_draft
      [ report, other ].each do |each_report|
        each_report.reload.should be_in_progress
        each_report.messages.sole.should be_kind_withdrawn
      end
    end

    it "reopens a closed report when the question is reported again" do
      report = report!
      report.team_close!(:dismissed, by: admin, body: "Вярна е.")

      report!(reason: "broken", note: "Пак не работи")
      report.reload.should be_open
      report.resolver.should be_nil
      report.messages.last.should be_kind_reopened
      report.messages.last.body.should eq("Пак не работи")
    end

    it "tells the editor that students are waiting, and comes back to the ticket after saving" do
      report = report!

      sign_in admin
      get "/overseer/questions/#{question.id}/edit", params: { return_to: "/overseer/question_reports/#{report.id}" }
      response.body.should include(I18n.t("overseer.questions.reports_waiting", count: 1))
      response.body.should include(%(name="return_to"))
    end

    it "keeps students out of the queue" do
      report = report!

      sign_in student
      get "/overseer/question_reports"
      response.should_not have_http_status(:ok)

      get "/overseer/question_reports/#{report.id}"
      response.should_not have_http_status(:ok)
    end
  end

  describe "the student's thread" do
    let(:question) { create(:question, text: "Колко е 2 + 3?", answer: "6", explanation: "2 + 3 = 6") }
    let!(:report) { QuestionReport.file!(question: question, user: student, reason: "wrong_answer", note: "Не е 6") }

    it "keeps a copy of the question as it was reported" do
      report.snapshot["answer"].should eq("6")
      report.snapshot["body"].should eq(question.body)
      report.changes_since_report.should eq([])
    end

    it "shows the conversation and what changed in the question" do
      question.update!(grading: { "expected" => "5" }, explanation: "2 + 3 = 5")
      report.team_reply!(by: admin, body: "Имаше право, отговорът е 5.")

      sign_in student
      get "/reports/#{report.id}"

      response.should have_http_status(:ok)
      response.body.should include("Не е 6")
      response.body.should include("Имаше право, отговорът е 5.")
      response.body.should include(I18n.t("report_thread.team"))
      response.body.should_not include(admin.name)
      response.body.should include(I18n.t("report_thread.what_changed"))
      response.body.should include("2 + 3 = 6")
      response.body.should include("2 + 3 = 5")
      response.body.should include(I18n.t("report_thread.ask_verdict"))
    end

    it "tells the student about a reply on „Днес“ and „Аз“ until they open it" do
      report.team_reply!(by: admin, body: "Поправихме я. Сега добре ли е?")

      sign_in student
      get "/home"
      response.body.should include("Поправихме я. Сега добре ли е?")
      response.body.should include(I18n.t("report_replies.answer_us"))

      get "/profile"
      response.body.should include(I18n.t("my_reports.unseen", count: 1))
      response.body.should include(%(<span class="nav-count">1</span>))

      get "/reports/#{report.id}"
      report.reload.seen_at.should be_present

      get "/home"
      response.body.should_not include(I18n.t("report_replies.kicker"))
    end

    it "does not mark a thread read while an admin is looking" do
      report.team_reply!(by: admin, body: "Поправихме я.")

      sign_in admin
      post "/impersonate/#{student.id}"
      get "/reports/#{report.id}"

      response.should have_http_status(:ok)
      report.reload.seen_at.should be_nil
    end

    it "lets the student add to a new report without changing its state" do
      sign_in student
      post "/reports/#{report.id}/respond", params: { kind: "comment", body: "И в обяснението е 6." }

      response.should redirect_to(report_path(report))
      report.reload.should be_open
      report.messages.sole.body.should eq("И в обяснението е 6.")
    end

    it "closes the report when the student confirms the fix" do
      report.team_reply!(by: admin, body: "Поправихме я.")

      sign_in student
      post "/reports/#{report.id}/respond", params: { kind: "confirmed", body: "" }

      report.reload.should be_resolved
      report.resolver.should eq(student)
      report.messages.last.should be_kind_confirmed
    end

    it "keeps the report in progress and back in the queue when the fix did not fix it" do
      report.team_reply!(by: admin, body: "Поправихме я.")

      sign_in student
      post "/reports/#{report.id}/respond", params: { kind: "not_fixed", body: "Още пише 6." }

      report.reload.should be_in_progress
      QuestionReport.awaiting_team.should eq([ report ])
    end

    it "reopens a closed report the student writes on" do
      report.team_close!(:resolved, by: admin, body: "Поправихме я.")

      sign_in student
      post "/reports/#{report.id}/respond", params: { kind: "not_fixed", body: "Не е поправена." }

      report.reload.should be_in_progress
      report.resolved_at.should be_nil
    end

    it "refuses a verdict before the team has answered, and an empty comment" do
      sign_in student
      post "/reports/#{report.id}/respond", params: { kind: "confirmed" }
      post "/reports/#{report.id}/respond", params: { kind: "comment", body: " " }

      flash[:alert].should eq(I18n.t("my_reports.empty_message"))
      report.reload.should be_open
      report.messages.should be_empty
    end

    it "archives a report and brings it back when the team writes again" do
      sign_in student
      post "/reports/#{report.id}/archive"

      response.should redirect_to(reports_path)
      report.reload.archived_at.should be_present
      get "/reports"
      response.body.should_not include(question.body_text.truncate(90))
      get "/reports", params: { archived: 1 }
      response.body.should include(question.body_text.truncate(90))

      report.team_reply!(by: admin, body: "Още един въпрос към теб.")
      report.reload.archived_at.should be_nil
    end

    it "shows „Моите сигнали“ on the profile only while a report is not archived" do
      sign_in student
      get "/profile"
      response.body.should include(reports_path)

      report.archive!
      get "/profile"
      response.body.should_not include(%(href="#{reports_path}"))

      report.team_reply!(by: admin, body: "Още един въпрос към теб.")
      get "/profile"
      response.body.should include(reports_path)
    end

    it "does not show „Моите сигнали“ to a student who never reported anything" do
      sign_in create(:user)
      get "/profile"

      response.body.should_not include(%(href="#{reports_path}"))
    end

    it "shows the fixed question with its answer and explanation, with nothing to answer" do
      sign_in student
      get "/reports/#{report.id}"
      response.body.should_not include(I18n.t("report_thread.fixed_question"))
      response.body.should_not include("2 + 3 = 6")

      question.update!(grading: { "expected" => "5" }, explanation: "2 + 3 = 5")
      get "/reports/#{report.id}"

      response.body.should include(I18n.t("report_thread.fixed_question"))
      response.body.should include("2 + 3 = 5")
      response.body.should include(I18n.t("answers.correct_answer"))
      response.body.should include(I18n.t("report_thread.what_changed"))
      response.body.should_not include(%(name="value"))
    end

    it "marks the right option of a fixed multiple-choice question" do
      choice = create(:question, :multiple_choice)
      choice_report = QuestionReport.file!(question: choice, user: student, reason: "missing_answer")
      choice_report.team_close!(:resolved, by: admin, corrected_question: choice)

      sign_in student
      get "/reports/#{choice_report.id}"

      choice.possible_answers.each { |option| response.body.should include(option.value) }
      response.body.should include(I18n.t("report_thread.correct_option"))
      response.body.should_not include("choice-button")
    end

    it "shows the question and why it is correct when nothing was wrong" do
      report.team_close!(:dismissed, by: admin, body: "Прочети пак условието.")

      sign_in student
      get "/reports/#{report.id}"

      response.body.should include(I18n.t("report_thread.checked_question"))
      response.body.should include("2 + 3 = 6")
    end

    it "draws the corrected version inside the message that names it, with nothing to follow" do
      corrected = create(:question, text: "Колко е 2 + 4?", answer: "6", explanation: "2 + 4 = 6")
      question.update!(status: :retired)
      report.team_close!(:resolved, by: admin, body: "Написахме я наново.", corrected_question: corrected)

      sign_in student
      get "/reports/#{report.id}"

      thread = response.body[response.body.index(I18n.t("report_thread.conversation"))..]
      thread.should include("Написахме я наново.", "Колко е 2 + 4?", "2 + 4 = 6", I18n.t("answers.correct_answer"))
      response.body.should include(I18n.t("report_thread.reported_question"))
      # Drawn once, in the message: the top of the page is the question as
      # reported (the new text appears again only inside the folded diff).
      response.body.should_not include(%(id="corrected-title"))
      response.body.should_not include(edit_overseer_question_path(corrected))

      sign_in admin
      get "/overseer/question_reports/#{report.id}"
      response.body.should include("2 + 4 = 6", edit_overseer_question_path(corrected))
    end

    it "shows the corrected version the team pointed to" do
      corrected = create(:question, text: "Колко е 2 + 4?", answer: "6", explanation: "2 + 4 = 6")
      question.update!(status: :retired)
      report.team_close!(:resolved, by: admin, body: "Написахме я наново.", corrected_question: corrected)

      sign_in student
      get "/reports/#{report.id}"

      response.body.should include(I18n.t("report_thread.corrected_version"))
      response.body.should include("Колко е 2 + 4?")
      response.body.should include("2 + 4 = 6")
    end

    it "takes a report out of the archive by hand" do
      report.archive!

      sign_in student
      delete "/reports/#{report.id}/archive"

      report.reload.archived_at.should be_nil
    end

    it "keeps other students out of a thread" do
      sign_in create(:user)
      get "/reports/#{report.id}"
      response.should have_http_status(:not_found)

      post "/reports/#{report.id}/archive"
      response.should have_http_status(:not_found)
      report.reload.archived_at.should be_nil
    end

    it "links the thread from the question" do
      assignment_question = Assignment.create!(user: student).
        assignment_questions.create!(question: question, position: 1)

      sign_in student
      get "/questions/#{assignment_question.id}"

      response.body.should include(report_path(report))
    end
  end

  describe "email about activity on a report" do
    let(:question) { create(:question, answer: "5") }
    let(:reporter) { create(:user, email: "eli@example.com", verified_at: Time.current) }
    let!(:report) { QuestionReport.file!(question: question, user: reporter, reason: "wrong_answer") }

    before { allow(Mailing).to receive(:enabled?).and_return(true) }

    def mails_to(address)
      ActionMailer::Base.deliveries.select { |mail| mail.to == [ address ] }
    end

    it "emails the reporter when the team comments or changes the status" do
      sign_in admin
      perform_enqueued_jobs do
        post "/overseer/question_reports/#{report.id}/comment", params: { body: "Погледнахме я." }
        post "/overseer/question_reports/#{report.id}/transition", params: { status: "dismissed", body: "Вярна е." }
      end

      mails = mails_to("eli@example.com")
      mails.size.should eq(2)
      mails.last.subject.should eq(I18n.t("mailers.report_activity.subjects.dismissed"))
    end

    it "emails each reporter when a change is applied to the linked reports" do
      other = create(:user, email: "bobi@example.com", verified_at: Time.current)
      QuestionReport.file!(question: question, user: other, reason: "typo")

      sign_in admin
      perform_enqueued_jobs do
        post "/overseer/question_reports/#{report.id}/comment", params: { body: "Поправихме я.", apply_to_related: "1" }
      end

      mails_to("eli@example.com").size.should eq(1)
      mails_to("bobi@example.com").size.should eq(1)
    end

    it "does not email the student about their own messages" do
      report.team_reply!(by: admin, body: "Погледнахме я.")
      ActionMailer::Base.deliveries.clear

      sign_in reporter
      perform_enqueued_jobs { post "/reports/#{report.id}/respond", params: { kind: "comment", body: "Благодаря!" } }

      ActionMailer::Base.deliveries.should be_empty
    end

    it "sends nothing to an unconfirmed address or a switched-off email" do
      reporter.update!(verified_at: nil)
      perform_enqueued_jobs { report.team_reply!(by: admin, body: "Първо.") }

      reporter.update!(verified_at: Time.current, report_activity: false)
      perform_enqueued_jobs { report.team_reply!(by: admin, body: "Второ.") }

      ActionMailer::Base.deliveries.should be_empty
    end

    it "emails the parents of a child who reported, including a child with no address of their own" do
      parent = create(:user, role: :parent, email: "mama@example.com", verified_at: Time.current)
      child = User.create_managed_child!(parent: parent, name: "Ани")
      child_report = QuestionReport.file!(question: question, user: child, reason: "typo")

      perform_enqueued_jobs { child_report.team_reply!(by: admin, body: "Поправихме я.") }

      mails = mails_to("mama@example.com")
      mails.size.should eq(1)
      mails.first.html_part.decoded.should include("Ани ни съобщи за проблем със задача")
    end

    it "emails the parents when a child files a report, with what the child said" do
      parent = create(:user, role: :parent, email: "mama@example.com", verified_at: Time.current)
      child = User.create_managed_child!(parent: parent, name: "Ани")
      assignment_question = Assignment.create!(user: child).assignment_questions.create!(question: question, position: 1)

      sign_in parent
      post "/switch-child/#{child.id}"
      perform_enqueued_jobs do
        post "/questions/#{assignment_question.id}/report", params: { reason: "wrong_answer", note: "Отговорът е 6" }
      end

      mail = mails_to("mama@example.com").sole
      mail.subject.should eq(I18n.t("mailers.report_filed.subject", name: "Ани"))
      [ mail.html_part.decoded, mail.text_part.decoded ].each do |body|
        body.should include("Отговорът е 6", I18n.t("reports.reasons.wrong_answer"))
        body.should include("/parents/children/#{child.id}/reports/#{QuestionReport.last.id}")
      end
    end

    it "emails the parents again when a closed report is reopened by a new one, not when an open one is rewritten" do
      parent = create(:user, role: :parent, email: "tate@example.com", verified_at: Time.current)
      ParentLink.create!(parent: parent, child: reporter)

      perform_enqueued_jobs { QuestionReport.file!(question: question, user: reporter, reason: "typo") }
      mails_to("tate@example.com").should be_empty

      report.team_close!(:dismissed, by: admin, body: "Вярна е.")
      ActionMailer::Base.deliveries.clear
      perform_enqueued_jobs { QuestionReport.file!(question: question, user: reporter, reason: "broken") }

      mails_to("tate@example.com").map(&:subject).should eq([ I18n.t("mailers.report_filed.subject", name: reporter.name) ])
      mails_to("eli@example.com").should be_empty
    end

    it "emails both the child and their parent when both have an address" do
      parent = create(:user, role: :parent, email: "tate@example.com", verified_at: Time.current)
      ParentLink.create!(parent: parent, child: reporter)

      perform_enqueued_jobs { report.team_reply!(by: admin, body: "Поправихме я.") }

      mails_to("eli@example.com").size.should eq(1)
      mails_to("tate@example.com").size.should eq(1)
    end

    it "offers the switch in Настройки" do
      sign_in reporter
      get "/settings"

      response.body.should include(I18n.t("email_preferences.kinds.report_activity.title"))
    end
  end

  describe "a parent in the conversation" do
    let(:parent) { create(:user, role: :parent, name: "Мама", verified_at: Time.current) }
    let(:child) { User.create_managed_child!(parent: parent, name: "Ани") }
    let(:question) { create(:question, answer: "5", explanation: "2 + 3 = 5") }
    let!(:report) { QuestionReport.file!(question: question, user: child, reason: "wrong_answer", note: "Не е 5") }

    it "lists the child's reports on the child's page, once there is one" do
      sign_in parent
      get "/parents/children/#{child.id}"
      response.body.should include(I18n.t("parents.children.tabs.reports"))

      get "/parents/children/#{child.id}", params: { tab: "reports" }
      response.body.should include(parents_child_report_path(child, report))

      other = User.create_managed_child!(parent: parent, name: "Боби")
      get "/parents/children/#{other.id}"
      response.body.should_not include(I18n.t("parents.children.tabs.reports"))
    end

    it "shows the conversation, the fixed question and a box to write in" do
      report.team_close!(:dismissed, by: admin, body: "Вярна е: 2 + 3 = 5.")

      sign_in parent
      get "/parents/children/#{child.id}/reports/#{report.id}"

      response.should have_http_status(:ok)
      response.body.should include("Не е 5", "Вярна е: 2 + 3 = 5.", "2 + 3 = 5")
      response.body.should include(I18n.t("report_thread.team"))
      response.body.should_not include(admin.name)
      response.body.should include(comment_parents_child_report_path(child, report))
      response.body.should_not include(I18n.t("report_thread.actions.confirmed"))
    end

    it "takes the parent's comment, which puts the report back in front of the team" do
      report.team_reply!(by: admin, body: "Погледнахме я.")

      sign_in parent
      post "/parents/children/#{child.id}/reports/#{report.id}/comment", params: { body: "Ани имаше предвид второто число." }

      response.should redirect_to(parents_child_report_path(child, report))
      message = report.messages.reload.last
      message.should be_from_family
      message.author.should eq(parent)
      QuestionReport.awaiting_team.should eq([ report ])
    end

    it "reopens a closed report the parent writes on" do
      report.team_close!(:dismissed, by: admin, body: "Вярна е.")

      sign_in parent
      post "/parents/children/#{child.id}/reports/#{report.id}/comment", params: { body: "Не е вярна — вижте пак." }

      report.reload.should be_in_progress
      report.messages.last.should be_kind_reopened
    end

    it "shows the parent's message to the child and the team as the parent's" do
      report.family_comment!(by: parent, body: "Ани имаше предвид второто число.")

      sign_in admin
      get "/overseer/question_reports/#{report.id}"
      response.body.should include(I18n.t("report_thread.parent", name: "Мама"))

      # A managed child has no login: the parent switches into their profile.
      sign_in parent
      post "/switch-child/#{child.id}"
      get "/reports/#{report.id}"
      response.body.should include(I18n.t("report_thread.parent", name: "Мама"))
    end

    it "keeps other parents out" do
      sign_in create(:user, role: :parent, verified_at: Time.current)
      get "/parents/children/#{child.id}/reports/#{report.id}"
      response.should have_http_status(:not_found)

      post "/parents/children/#{child.id}/reports/#{report.id}/comment", params: { body: "Здравейте" }
      report.messages.reload.should be_empty
    end
  end
end
