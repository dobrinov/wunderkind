require "rails_helper"

# The admin question browser: facets, saved views, sorts and template
# grouping over the bank, each row carrying how students have fared with it,
# and a preview pane for the selected question.
describe "The question browser", type: :request do
  let(:admin) { create(:user, role: :admin, verified_at: Time.current) }
  let(:area) { Topic.create!(name: "Дроби и проценти") }
  let(:fractions) { Topic.create!(name: "Дроби", parent: area) }
  let(:decimals) { Topic.create!(name: "Десетични", parent: area) }

  before { sign_in admin }

  def answer!(question, correct: false, skipped: false, value: "1", response: nil, user: create(:user))
    assignment = Assignment.create!(user: user)
    row = assignment.assignment_questions.create!(question: question, position: 1)
    UserAnswer.create!(user: user, assignment_question: row, value: skipped ? "" : value, correct: correct, skipped: skipped,
                       response: response || (skipped ? { "skipped" => true } : { "value" => value }))
  end

  def answers!(question, correct: 0, wrong: 0, skipped: 0)
    correct.times { answer!(question, correct: true) }
    wrong.times { answer!(question) }
    skipped.times { answer!(question, skipped: true) }
  end

  def listed_ids
    response.body.scan(%r{data-edit-url="/overseer/questions/(\d+)/edit}).flatten.map(&:to_i)
  end

  describe "stats" do
    it "shows right, wrong and „не съм го учил“ out of every answer, leaving pending free text out" do
      question = create(:question, text: "Колко е 3/4 от 28?")
      answers!(question, correct: 5, wrong: 2, skipped: 3)
      answer!(question, response: { "value" => "дълго", "verdict" => "pending_review" })

      get "/overseer/questions"

      QuestionStats.split(question).to_a.should eq([ 5, 2, 3 ])
      response.body.should include(I18n.t("overseer.questions.browser.answers", count: 10))
      response.body.should include("50% · 20% ·")
      response.body.should include(I18n.t("overseer.questions.browser.skipped_share", share: 30))
    end

    it "reads a page of questions in one grouped query" do
      questions = create_list(:question, 3)
      questions.each { |question| answers!(question, correct: 1, skipped: 1) }

      queries = []
      callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?("user_answers") }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get "/overseer/questions" }

      # One for the page; the pane's own read of the selected question is the
      # only other, and it asks about one id.
      queries.count { |sql| sql.include?('"assignment_questions"."question_id" IN') }.should eq(1)
    end

    it "renders the body as a student sees it, fractions stacked" do
      create(:question, text: "Колко е 3/4 от 28?")

      get "/overseer/questions"

      response.body.should include('<span class="frac" role="math" aria-label="3/4">')
    end
  end

  describe "filters" do
    it "narrows to an area with all its leaves, or to one leaf" do
      in_fractions = create(:question, topics: [ fractions ])
      in_decimals = create(:question, topics: [ decimals ])
      elsewhere = create(:question)

      get "/overseer/questions", params: { topic_ids: [ area.id ] }
      listed_ids.should contain_exactly(in_fractions.id, in_decimals.id)

      get "/overseer/questions", params: { topic_ids: [ decimals.id ] }
      listed_ids.should eq([ in_decimals.id ])
      listed_ids.should_not include(elsewhere.id)
    end

    it "counts each facet as choosing it would give" do
      create_list(:question, 2, topics: [ fractions ])
      create(:question, topics: [ decimals ], answer_type: :exact_value)

      filter = QuestionFilter.new(topic_ids: [ decimals.id.to_s ])

      filter.topic_counts[:leaves].should include(fractions.id => 2, decimals.id => 1)
      filter.topic_counts[:areas].should include(area.id => 3)
      filter.answer_type_counts.should eq("exact_value" => 1)
    end

    it "filters by Elo range, answer type, number and text" do
      low = create(:question, elo: 800, text: "Събери 2 и 3")
      high = create(:question, :multiple_choice, elo: 1500, text: "Избери по-голямото")

      get "/overseer/questions", params: { elo_min: 1000 }
      listed_ids.should eq([ high.id ])

      get "/overseer/questions", params: { answer_types: [ "exact_value" ] }
      listed_ids.should eq([ low.id ])

      get "/overseer/questions", params: { q: "##{high.id}" }
      listed_ids.should eq([ high.id ])

      get "/overseer/questions", params: { q: "събери" }
      listed_ids.should eq([ low.id ])
    end

    it "filters by what a question has" do
      hinted = create(:question)
      hinted.create_hint!(ladder: [ "Помисли за половината." ])
      reported = create(:question)
      reported.reports.create!(user: create(:user), reason: :typo)
      suggested = create(:question, suggested_by: create(:user))
      plain = create(:question)

      { "hints" => hinted, "report" => reported, "suggested" => suggested }.each do |key, question|
        get "/overseer/questions", params: { has: [ key ] }
        listed_ids.should eq([ question.id ])
      end
      listed_ids.should_not include(plain.id)
    end

    it "shows a removable token per filter" do
      get "/overseer/questions", params: { topic_ids: [ fractions.id ], elo_min: 900, elo_max: 1300 }

      response.body.should include(I18n.t("overseer.questions.browser.tokens.topic", name: "Дроби"))
      response.body.should include(I18n.t("overseer.questions.browser.tokens.elo", from: "900", to: "1300"))
      response.body.should include(CGI.escapeHTML(overseer_questions_path(topic_ids: [ fractions.id.to_s ])))
    end
  end

  describe "views" do
    it "„Много пропускани“ needs a high skip share out of enough answers" do
      skipped = create(:question)
      answers!(skipped, correct: 10, skipped: 10)
      rarely = create(:question)
      answers!(rarely, skipped: 3)
      fine = create(:question)
      answers!(fine, correct: 18, skipped: 2)

      get "/overseer/questions", params: { view: "skipped" }

      listed_ids.should eq([ skipped.id ])
      QuestionFilter.new({}).view_counts["skipped"].should eq(1)
    end

    it "counts and lists reported, hintless, published and retired questions" do
      reported = create(:question)
      reported.reports.create!(user: create(:user), reason: :typo)
      hinted = create(:question)
      hinted.create_hint!(ladder: [ "Помисли." ])
      retired = create(:question, status: :retired)

      counts = QuestionFilter.new({}).view_counts
      counts.should include("published" => 2, "reported" => 1, "no_hints" => 1, "retired" => 1)

      get "/overseer/questions", params: { view: "reported" }
      listed_ids.should eq([ reported.id ])
      get "/overseer/questions", params: { view: "retired" }
      listed_ids.should eq([ retired.id ])
      get "/overseer/questions", params: { view: "no_hints" }
      listed_ids.should eq([ reported.id ])
    end
  end

  describe "sorting" do
    it "orders by skips, answers, Elo and age" do
      a = create(:question, elo: 900)
      b = create(:question, elo: 1100)
      c = create(:question, elo: 1000)
      answers!(a, correct: 1, skipped: 1)
      answers!(b, correct: 5)
      answers!(c, skipped: 3)

      get "/overseer/questions", params: { sort: "skipped" }
      listed_ids.should eq([ c.id, a.id, b.id ])
      get "/overseer/questions", params: { sort: "answered" }
      listed_ids.should eq([ b.id, c.id, a.id ])
      get "/overseer/questions", params: { sort: "elo_desc" }
      listed_ids.should eq([ b.id, c.id, a.id ])
      get "/overseer/questions", params: { sort: "newest" }
      listed_ids.should eq([ c.id, b.id, a.id ])
    end
  end

  describe "grouping by template" do
    it "collapses questions that differ only in their numbers to one row with a count" do
      first = create(:question, text: "Колко е 3 + 4?", elo: 700)
      create(:question, text: "Колко е 5 + 6?", elo: 800)
      create(:question, text: "Колко е 12 + 30?", elo: 900)
      other = create(:question, text: "Колко страни има триъгълникът?", elo: 1000)

      get "/overseer/questions", params: { group: "1" }

      listed_ids.should eq([ first.id, other.id ])
      response.body.should include(I18n.t("overseer.questions.browser.in_template", count: 2))
    end

    it "lists a whole template" do
      first = create(:question, text: "Колко е 3 + 4?")
      second = create(:question, text: "Колко е 5 + 6?")
      create(:question, text: "Колко е 5 · 6?")

      get "/overseer/questions", params: { template: first.id }

      listed_ids.should contain_exactly(first.id, second.id)
    end
  end

  describe "the preview pane" do
    it "shows the selected question with the right option marked, its stats and its report" do
      question = create(:question, :multiple_choice, answer: "21", explanation: "28 : 4 = 7, а 3 · 7 = 21.")
      answers!(question, correct: 2, skipped: 2)
      report = question.reports.create!(user: create(:user, name: "Мая Петрова"), reason: :wrong_answer)

      get "/overseer/questions", params: { selected: question.id }, headers: { "Turbo-Frame" => "question-pane" }

      response.body.should include('<turbo-frame id="question-pane">')
      response.body.should include("border-green-600")
      response.body.should include("28 : 4 = 7, а 3 · 7 = 21.")
      response.body.should include(I18n.t("overseer.questions.browser.report_banner", count: 1))
      response.body.should include(overseer_question_report_path(report))
      response.body.should include(">50%<")
      # A pane request does not run the list again.
      response.body.should_not include(I18n.t("overseer.questions.browser.legend"))
    end

    it "selects the first row when nothing is chosen" do
      first = create(:question, elo: 600)
      create(:question, elo: 700)

      get "/overseer/questions"

      response.body.should match(/aria-current="true"[^>]*data-edit-url="\/overseer\/questions\/#{first.id}\/edit/)
    end
  end

  it "is closed to non-admins" do
    sign_in create(:user)
    get "/overseer/questions"

    response.should redirect_to("/")
  end
end
