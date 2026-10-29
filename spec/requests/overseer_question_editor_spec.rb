require "rails_helper"

# The admin question editor: opened from a list it can walk, with the hint
# ladder saved inline, a warning before an option students already chose is
# changed, and a revision for every change an admin makes.
describe "The question editor", type: :request do
  let(:admin) { create(:user, role: :admin, verified_at: Time.current, name: "Деян Добринов") }
  let(:topic) { Topic.create!(name: "Дроби") }

  before { sign_in admin }

  def edit_params(question, overrides = {})
    { question: { body_source: question.body_text, answer_type: question.answer_type, expected: question.grading["expected"],
                  status: question.status, elo: question.elo, explanation: question.explanation.to_s,
                  topic_ids: [ "" ] + question.topic_ids.map(&:to_s) }.merge(overrides) }
  end

  def choose!(question, option, user: create(:user))
    assignment = Assignment.create!(user: user)
    row = assignment.assignment_questions.create!(question: question, position: 1)
    UserAnswer.create!(user: user, assignment_question: row, value: option.value, correct: option.correct,
                       response: { "selected_ids" => [ option.id ] })
  end

  describe "walking the list it came from" do
    let!(:first) { create(:question, elo: 700) }
    let!(:second) { create(:question, elo: 800) }
    let!(:third) { create(:question, elo: 900) }

    it "says where in the list the question is" do
      get "/overseer/questions/#{second.id}/edit", params: { from: { sort: "elo_asc" } }

      response.body.should include(I18n.t("overseer.questions.editor.position", index: 2, total: 3))
      response.body.should include(%(href="/overseer/questions/#{first.id}/edit))
      response.body.should include(%(href="/overseer/questions/#{third.id}/edit))
      response.body.should include(I18n.t("overseer.questions.editor.save_next"))
    end

    it "saves and goes on to the next one in the list's own order" do
      patch "/overseer/questions/#{second.id}", params: edit_params(second, elo: 950).merge(next: "1", from: { sort: "elo_desc" })

      # Elo ↓ over 900, 800, 700 as the list stood: the one after it is the
      # first, even though the save moved it to the top.
      response.should redirect_to(edit_overseer_question_path(first, from: { sort: "elo_desc" }))
      second.reload.elo.should eq(950)
    end

    it "saves and returns to the list, the question still selected" do
      patch "/overseer/questions/#{first.id}", params: edit_params(first).merge(from: { view: "published" })

      response.should redirect_to(overseer_questions_path(view: "published", selected: first.id))
    end

    it "still goes back to the ticket it was opened from" do
      report = first.reports.create!(user: create(:user), reason: :typo)

      patch "/overseer/questions/#{first.id}", params: edit_params(first).merge(return_to: "/overseer/question_reports/#{report.id}")

      response.should redirect_to("/overseer/question_reports/#{report.id}")
    end
  end

  describe "hints, inline" do
    let(:question) { create(:question, answer: "21") }

    it "saves the ladder with the question, approved when ticked" do
      patch "/overseer/questions/#{question.id}",
            params: edit_params(question).merge(hint: { ladder: [ "Колко е една четвърт?", "Три пъти по толкова.", "", "" ] }, approve_hints: "1")

      question.reload.hint.ladder.should eq([ "Колко е една четвърт?", "Три пъти по толкова." ])
      question.hint.should be_reviewed
    end

    it "keeps the original approval when an approved ladder is saved unchanged, and clears it when unticked" do
      stamp = 3.days.ago.change(usec: 0)
      question.create_hint!(ladder: [ "Колко е една четвърт?" ], reviewed_at: stamp)

      patch "/overseer/questions/#{question.id}", params: edit_params(question).merge(hint: { ladder: [ "Колко е една четвърт?" ] }, approve_hints: "1")
      question.hint.reload.reviewed_at.should eq(stamp)

      patch "/overseer/questions/#{question.id}", params: edit_params(question).merge(hint: { ladder: [ "Колко е една четвърт?" ] })
      question.hint.reload.should_not be_reviewed
    end

    it "refuses a rung that gives the answer away, saving nothing" do
      patch "/overseer/questions/#{question.id}",
            params: edit_params(question, elo: 1500).merge(hint: { ladder: [ "Отговорът е 21." ] }, approve_hints: "1")

      response.should have_http_status(:unprocessable_entity)
      response.body.should include(CGI.escapeHTML(I18n.t("overseer.questions.editor.hint_leaks", rung: "Отговорът е 21.")))
      question.reload.hint.should be_nil
      question.elo.should_not eq(1500)
    end

    it "removes the hint when the ladder is emptied" do
      question.create_hint!(ladder: [ "Колко е една четвърт?" ])

      patch "/overseer/questions/#{question.id}", params: edit_params(question).merge(hint: { ladder: [ "", "" ] })

      question.reload.hint.should be_nil
    end

    it "sends the old hint page to the editor's hint section" do
      get "/overseer/questions/#{question.id}/hint"

      response.should redirect_to(edit_overseer_question_path(question, anchor: "hints"))
    end
  end

  describe "options students already chose" do
    it "counts the students behind each option and warns before it is changed" do
      question = create(:question, :multiple_choice, answer: "21")
      wrong = question.possible_answers.find_by(correct: false)
      3.times { choose!(question, wrong) }
      repeat = create(:user)
      2.times { choose!(question, wrong, user: repeat) }

      QuestionStats.option_choosers(question).should eq(wrong.id => 4)

      get "/overseer/questions/#{question.id}/edit"

      response.body.should include(%(data-chosen="4" data-original="wrong"))
      response.body.should include(I18n.t("overseer.questions.editor.chosen", count: 4))
      response.body.should include(CGI.escapeHTML(I18n.t("overseer.questions.editor.option_changed", count: 4, was: "wrong")))
    end

    it "shows the most common wrong answer" do
      question = create(:question, :multiple_choice, answer: "21")
      wrong = question.possible_answers.find_by(correct: false)
      2.times { choose!(question, wrong) }
      choose!(question, question.possible_answers.find_by(correct: true))

      get "/overseer/questions/#{question.id}/edit"

      response.body.should include(CGI.escapeHTML(I18n.t("overseer.questions.editor.common_wrong_value", value: "wrong", share: 100)))
    end
  end

  describe "revisions" do
    it "records what changed, newest first, and shows them as history" do
      question = create(:question, answer: "21", elo: 1000, explanation: "Старо.")

      patch "/overseer/questions/#{question.id}", params: edit_params(question, elo: 1100, explanation: "Ново.", topic_ids: [ topic.id ])

      revision = question.revisions.sole
      revision.author.should eq(admin)
      revision.action.should eq("updated")
      revision.diff.should eq("elo" => [ 1000, 1100 ], "explanation" => [ "Старо.", "Ново." ], "topics" => [ [], [ "Дроби" ] ])

      get "/overseer/questions/#{question.id}/edit"
      response.body.should include("Elo 1000 → 1100")
    end

    it "records nothing for a save that changed nothing" do
      question = create(:question, answer: "21")

      patch "/overseer/questions/#{question.id}", params: edit_params(question)

      question.revisions.should be_empty
    end

    it "records a create, a hide, a retirement and a restore" do
      post "/overseer/questions", params: { question: { body_source: "Колко е 2 + 2?", answer_type: "exact_value", expected: "4",
                                                        status: "published", elo: 700, topic_ids: [ topic.id ] } }
      question = Question.last
      post "/overseer/questions/#{question.id}/hide"
      question.reload.should be_draft
      question.update!(status: :published)
      post "/overseer/questions/#{question.id}/retire"
      post "/overseer/questions/#{question.id}/restore"

      question.revisions.newest_first.map(&:action).should eq(%w[restored retired hidden created])
      question.revisions.find_by(action: "created").diff["body"].should eq([ nil, "Колко е 2 + 2?" ])
    end

    it "says an untouched imported question was imported" do
      question = create(:question)

      get "/overseer/questions/#{question.id}/edit"

      response.body.should include(I18n.t("overseer.questions.editor.history.import"))
    end
  end

  describe "the right column" do
    it "shows how students do and the size of the template" do
      question = create(:question, text: "Колко е 3 + 4?", answer: "7")
      create(:question, text: "Колко е 5 + 6?")
      assignment = Assignment.create!(user: create(:user))
      row = assignment.assignment_questions.create!(question: question, position: 1)
      UserAnswer.create!(user: assignment.user, assignment_question: row, value: "", correct: false, skipped: true, response: { "skipped" => true })

      get "/overseer/questions/#{question.id}/edit"

      response.body.should include(I18n.t("overseer.questions.editor.perf_skipped", share: 100))
      response.body.should include(I18n.t("overseer.questions.editor.template", count: 2))
    end

    it "copies a question into a new form" do
      source = create(:question, :multiple_choice, answer: "21", topics: [ topic ])

      get "/overseer/questions/new", params: { copy_of: source.id }

      response.body.should include(%(value="21"))
      response.body.should match(/<input[^>]*id="question_topic_#{topic.id}"[^>]*checked="checked"/)
    end
  end

  it "keeps a widget it cannot edit as it was stored" do
    question = create(:question, answer_type: :interactive,
                                 grading: { "widget" => "geoboard", "params" => { "size" => 5 }, "solution" => { "points" => [ [ 0, 0 ] ] } })

    patch "/overseer/questions/#{question.id}", params: edit_params(question).merge(question: edit_params(question)[:question].merge(widget: "geoboard"))

    question.reload.grading["widget"].should eq("geoboard")
    question.grading["solution"].should eq("points" => [ [ 0, 0 ] ])
  end
end
