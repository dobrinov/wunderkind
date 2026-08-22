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
      ChallengeMatchmaker.call(user: student)
      ChallengeMatchmaker.call(user: opponent)
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

    it "lists reported questions with the reasons and the notes" do
      report!(note: "Верният отговор е 6")

      sign_in admin
      get "/overseer/question_reports"

      response.should have_http_status(:ok)
      response.body.should include(question.body_text)
      response.body.should include(I18n.t("reports.reasons.wrong_answer"))
      response.body.should include("Верният отговор е 6")
      response.body.should include(I18n.t("overseer.reports.count", count: 1))
    end

    it "counts the open reports in the admin nav" do
      report!
      report!(user: create(:user))

      sign_in admin
      get "/overseer/questions"

      response.body.should include("#{I18n.t("overseer.nav.reports")} (2)")
      response.body.should include("⚑ 2")
    end

    it "closes the whole pile on one question" do
      report!
      report!(user: create(:user))

      sign_in admin
      post "/overseer/question_reports/#{question.id}/resolve"

      response.should redirect_to(overseer_question_reports_path)
      QuestionReport.open.count.should be_zero
      QuestionReport.resolved.count.should eq(2)
      QuestionReport.first.resolver.should eq(admin)
    end

    it "dismisses a pile without touching the question" do
      report!

      sign_in admin
      post "/overseer/question_reports/#{question.id}/dismiss"

      QuestionReport.sole.should be_dismissed
      question.reload.should be_published
    end

    it "takes a broken question out of circulation" do
      report!

      sign_in admin
      post "/overseer/question_reports/#{question.id}/withdraw"

      question.reload.should be_draft
      QuestionReport.sole.should be_resolved
    end

    it "reopens the pile when the question is reported again" do
      report!

      sign_in admin
      post "/overseer/question_reports/#{question.id}/dismiss"

      report!(reason: "broken")
      QuestionReport.open.count.should eq(1)
      QuestionReport.sole.resolver.should be_nil
    end

    it "keeps students out of the queue" do
      report!

      sign_in student
      get "/overseer/question_reports"

      response.should_not have_http_status(:ok)
    end
  end
end
