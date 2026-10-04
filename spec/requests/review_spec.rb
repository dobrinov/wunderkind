require "rails_helper"

describe "Reviewing your own mistakes", type: :request do
  let(:student) { create(:user, elo: 1200) }

  # One question, answered once, in its own session — which is how the app
  # serves them and the only way a second attempt can exist as a second row.
  def answer(question, value:, skipped: false)
    assignment = Assignment.create!(user: student)
    aq = assignment.assignment_questions.create!(question: question, position: 1)

    if skipped
      AnswerSubmission.skip(assignment_question: aq, user: student)
    else
      AnswerSubmission.call(assignment_question: aq, user: student, raw: { value: value })
    end

    aq
  end

  describe AnswerLog do
    it "lists only the latest answer to each question, so a fixed mistake drops off" do
      fixed = create(:question, answer: "42")
      still_wrong = create(:question, answer: "42")

      answer(fixed, value: "1")
      answer(still_wrong, value: "1")
      AnswerLog.wrong(student).pluck(:question_id).should contain_exactly(fixed.id, still_wrong.id)

      answer(fixed, value: "42")
      AnswerLog.wrong(student).pluck(:question_id).should contain_exactly(still_wrong.id)
    end

    it "keeps skips in their own list, out of the mistakes" do
      skipped = create(:question)
      answer(skipped, value: nil, skipped: true)

      AnswerLog.skipped(student).pluck(:question_id).should eq([ skipped.id ])
      AnswerLog.wrong(student).should be_empty
    end

    it "does not call a free-text answer awaiting a grader a mistake" do
      pending_question = create(:question, :free_text)
      answer(pending_question, value: "защото е така")

      UserAnswer.last.should be_pending_review
      AnswerLog.wrong(student).should be_empty
    end
  end

  describe "the review screen" do
    it "shows both lists with their counts" do
      wrong = create(:question, answer: "42", text: "Колко е 2 + 2?")
      skipped = create(:question, text: "Колко е синусът?")
      answer(wrong, value: "1")
      answer(skipped, value: nil, skipped: true)

      sign_in student
      get "/review"

      response.should have_http_status(:ok)
      response.body.should include("Колко е 2 + 2?")
      response.body.should_not include("Колко е синусът?")

      get "/review?filter=skipped"
      response.body.should include("Колко е синусът?")
      response.body.should_not include("Колко е 2 + 2?")
    end

    it "falls back to the mistakes list rather than trusting a hand-typed filter" do
      sign_in student
      get "/review?filter=../etc/passwd"

      response.should have_http_status(:ok)
      response.body.should include(I18n.t("review.empty_wrong"))
    end

    it "offers no practice button when there is nothing wrong to practise" do
      answer(create(:question), value: nil, skipped: true)

      sign_in student
      get "/review"

      response.body.should_not include(I18n.t("review.practice_title"))
    end
  end

  describe "practising the mistakes" do
    it "builds a session of exactly the questions still got wrong, oldest first" do
      old = create(:question, answer: "42")
      recent = create(:question, answer: "42")
      answer(old, value: "1")
      UserAnswer.last.update!(created_at: 3.weeks.ago)
      answer(recent, value: "1")

      sign_in student
      post "/review/practice"

      assignment = student.assignments.order(:id).last
      assignment.should be_mistakes
      assignment.questions.map(&:id).should eq([ old.id, recent.id ])
      response.should redirect_to(question_path(assignment.next_assignment_question))
    end

    # The card promised ten and the session has to be ten: the pool filter runs
    # before the list is cut down, not after.
    it "fills the session from live questions when the oldest mistakes were withdrawn" do
      withdrawn = Array.new(3) { create(:question, answer: "42") }
      live = Array.new(3) { create(:question, answer: "42") }

      (withdrawn + live).each { |question| answer(question, value: "1") }
      withdrawn.each { |question| question.update!(status: :draft) }

      MistakePractice.available_count(student).should eq(3)

      sign_in student
      post "/review/practice"

      student.assignments.order(:id).last.questions.map(&:id).should eq(live.map(&:id))
    end

    it "leaves out a question the admin has since withdrawn from circulation" do
      withdrawn = create(:question, answer: "42")
      answer(withdrawn, value: "1")
      withdrawn.update!(status: :draft)

      sign_in student
      post "/review/practice"

      response.should redirect_to(review_path)
      flash[:alert].should eq(I18n.t("review.nothing_to_practise"))
    end

    # The point of the whole kind: see Assignment#measured?.
    it "teaches and pays, but moves no rating" do
      question = create(:question, answer: "42", elo: 1000)
      answer(question, value: "1")

      student.reload
      elo_before = student.elo
      xp_before = student.total_xp
      skill_before = student.skills.map { |skill| [ skill.id, skill.rating, skill.games_count ] }
      question_elo_before = question.reload.elo

      sign_in student
      post "/review/practice"
      aq = student.assignments.order(:id).last.next_assignment_question
      post "/questions/#{aq.id}/answer", params: { value: "42" }

      student.reload
      student.elo.should eq(elo_before)
      question.reload.elo.should eq(question_elo_before)
      student.skills.map { |skill| [ skill.id, skill.rating, skill.games_count ] }.should eq(skill_before)

      # ...while the answer itself, the XP and the streak are entirely real.
      aq.reload.user_answer.should be_correct
      student.total_xp.should be > xp_before
      AnswerLog.wrong(student).should be_empty
    end

    # Paying ATTEMPT_AMOUNT here would be a faucet: the question stays on the
    # list (only a correct answer takes it off), so the same session comes
    # straight back.
    it "pays nothing for getting a mistake wrong again" do
      question = create(:question, answer: "42")
      answer(question, value: "1")
      student.reload
      xp_before = student.total_xp

      sign_in student
      post "/review/practice"
      aq = student.assignments.order(:id).last.next_assignment_question
      post "/questions/#{aq.id}/answer", params: { value: "still wrong" }

      # Nothing for the answer. The session bonus still lands: a student who
      # tries their mistakes again and still gets them wrong has done the work
      # — that is the student this whole screen is for — and 15 XP for a
      # session is below what honest practice pays for the same minutes.
      student.xp_events.where(reason: "answer").count.should eq(1) # the original, graded one
      student.reload.total_xp.should eq(xp_before + Xp::SESSION_BONUS)
    end

    it "refuses the skip on the server, not only in the markup" do
      question = create(:question, answer: "42")
      answer(question, value: "1")

      sign_in student
      post "/review/practice"
      aq = student.assignments.order(:id).last.next_assignment_question
      post "/questions/#{aq.id}/skip"

      response.should redirect_to(question_path(aq))
      aq.reload.user_answer.should be_nil
      AnswerLog.skipped(student).should be_empty
      AnswerLog.wrong(student).pluck(:question_id).should eq([ question.id ])
    end

    # Real work, so it counts as effort; no measurement, so it counts as none.
    it "is effort everywhere it is effort, and evidence nowhere" do
      question = create(:question, answer: "42", elo: 1000)
      answer(question, value: "1")

      sign_in student
      post "/review/practice"
      aq = student.assignments.order(:id).last.next_assignment_question
      post "/questions/#{aq.id}/answer", params: { value: "42" }

      student.reload
      student.user_answers.attempted.count.should eq(2)
      student.user_answers.measured.count.should eq(1)

      # The three readers that take an answer as evidence about the student.
      Dispatcher.calibrating?(student).should be(true)
      PracticeHistory.new(student).total_answers.should eq(2)
      PerformanceTrend.new(student).send(:tally, student, 9.weeks.ago.to_date).
        values.sum { |(_, attempts, _)| attempts }.should eq(1)
    end

    it "hides the shrug button, which this session has already been told about" do
      question = create(:question, answer: "42")
      answer(question, value: "1")

      sign_in student
      post "/review/practice"
      aq = student.assignments.order(:id).last.next_assignment_question

      get "/questions/#{aq.id}"
      response.body.should include(I18n.t("answers.not_taught")) # rendered...
      response.body.should match(/hidden[^>]*>\s*<form[^>]*#{Regexp.escape(question_skip_path(aq))}/m)
    end
  end

  describe "the history card" do
    it "counts the skips beside the answers without folding them in" do
      answered = create(:question, answer: "42")
      answer(answered, value: "42")
      answer(create(:question), value: nil, skipped: true)

      history = PracticeHistory.new(student)
      history.total_answers.should eq(1)
      history.total_skipped.should eq(1)
      history.accuracy.should eq(100)

      sign_in student
      get "/calendar"
      response.body.should include(I18n.t("home.stat_skipped"))
      response.body.should include(I18n.t("home.review_link"))
    end
  end
end
