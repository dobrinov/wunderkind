require "rails_helper"

describe "Placing a new student", type: :request do
  # A bank with a known spread, so the search has somewhere to bisect.
  before { (600..2800).step(50).each { |elo| create(:question, elo: elo, answer: "42") } }

  let(:student) { create(:user) }

  # Answers the session as a student whose true level is `level`: everything at
  # or below it right, everything above it wrong.
  def sit_placement(user, level:, questions: Placement::QUESTION_COUNT)
    assignment = Placement.start!(user)

    questions.times do
      aq = assignment.assignment_questions.includes(:question).where.missing(:user_answer).first
      break if aq.nil?

      # Through AnswerSubmission, not straight into the table: what this has to
      # prove is what the real flow does, and the real flow grades, pays XP and
      # would move Elo if the session were measured.
      AnswerSubmission.call(assignment_question: aq, user: user,
                            raw: { value: aq.question.elo <= level ? "42" : "0" })
      Placement.advance!(assignment)
    end

    assignment
  end

  describe Placement do
    it "opens on an easy question, never in the middle of the bank" do
      assignment = Placement.start!(student)
      floor, ceiling = Placement.range

      first = assignment.questions.first.elo
      first.should be < (floor + ceiling) / 2
      first.should be <= floor + Placement::CLIMB
    end

    # The property that matters: wherever a student actually is, this finds it.
    it "places a student close to their real level, across the range" do
      [ 700, 1100, 1600, 2300 ].each do |level|
        user = create(:user)
        sit_placement(user, level: level)

        user.reload.elo.should be_within(120).of(level)
      end
    end

    it "climbs while the answers are right and bisects once one is wrong" do
      assignment = sit_placement(student, level: 1300)
      asked = assignment.questions.map(&:elo)

      # Doubling steps up from the floor...
      asked.first(3).each_cons(2) { |a, b| b.should be > a }
      # ...then closing in.
      asked.last(3).each_cons(2) { |a, b| (b - a).abs.should be < 120 }
      assignment.questions.map(&:id).uniq.size.should eq(assignment.questions.size)
    end

    it "reads a skip as too hard rather than as nothing" do
      assignment = Placement.start!(student)
      aq = assignment.assignment_questions.first
      AnswerSubmission.skip(assignment_question: aq, user: student)

      _low, high, _ceiling = Placement.bracket(assignment)
      high.should eq(aq.question.elo)
    end

    it "finishes by stamping the rating and the date, and ends calibration" do
      Dispatcher.calibrating?(student).should be(true)

      sit_placement(student, level: 1100)

      student.reload.placed_at.should be_present
      student.elo.should be_within(120).of(1100)
      Dispatcher.calibrating?(student).should be(false)
    end

    # The session is all measurement, but not the per-answer kind: letting Elo
    # run as well would move the rating twice by two different methods.
    it "moves no question's Elo and no skill while it runs" do
      question_elos = Question.order(:id).pluck(:id, :elo).to_h

      sit_placement(student, level: 1300)

      Question.order(:id).pluck(:id, :elo).to_h.should eq(question_elos)
      student.skills.should be_empty
    end

    # The half of the exclusion that is easy to leave undone: no rating moves,
    # but every count that reads an answer as evidence still sees eight of them.
    it "leaves its answers out of everything that reads an answer as evidence" do
      sit_placement(student, level: 1300)

      student.user_answers.count.should eq(Placement::QUESTION_COUNT)
      student.user_answers.measured.count.should eq(0)
    end

    # It is still eight problems a child sat down and did.
    it "pays for the effort all the same" do
      sit_placement(student, level: 1300)

      student.reload.total_xp.should be > 0
      student.current_streak.should eq(1)
    end

    it "places a student who misses everything at the floor" do
      sit_placement(student, level: 0)

      student.reload.elo.should eq(Placement.range.first)
    end
  end

  describe "the flow" do
    it "takes a new student straight into it from sign-up" do
      post "/sign-up", params: { name: "Мими", email: "mimi@example.com", password: "secret123", role: "student" }

      response.should redirect_to("/placements/new")
      follow_redirect!
      response.body.should include(I18n.t("placement.intro_start"))
    end

    # The redirect out of sign-up is a GET, and `create` is not one.
    it "greets a student on a page they can actually be sent to" do
      sign_in student
      get "/placements/new"

      response.should have_http_status(:ok)
      response.body.should include(I18n.t("placement.intro_points.honest"))
    end

    it "does not offer a second placement to somebody already placed" do
      sit_placement(student, level: 1100)

      sign_in student
      get "/placements/new"

      response.should redirect_to("/calendar")
    end

    # The rating of a child with real history was earned; an eight-question
    # estimate must not be allowed to overwrite it.
    it "does not offer it to a student whose rating real answers already settled" do
      Dispatcher::CALIBRATION_ANSWERS.times do
        aq = Assignment.create!(user: student).
          assignment_questions.create!(question: create(:question, status: :draft), position: 1)
        aq.create_user_answer!(user: student, value: "42", correct: true, response: { "value" => "42" })
      end

      sign_in student
      get "/calendar"
      response.body.should_not include(I18n.t("placement.cta_title"))

      post "/placements"
      response.should redirect_to("/calendar")
      student.assignments.placement.should be_empty
    end

    it "leaves a parent's sign-up where it was" do
      post "/sign-up", params: { name: "Ивана", email: "ivana@example.com", password: "secret123", role: "parent" }

      response.should redirect_to("/parents/children")
    end

    it "serves one question at a time and ends on the result" do
      sign_in student
      post "/placements"

      assignment = student.assignments.placement.last
      assignment.assignment_questions.size.should eq(1)
      response.should redirect_to(question_path(assignment.next_assignment_question))

      Placement::QUESTION_COUNT.times do
        aq = assignment.assignment_questions.where.missing(:user_answer).first
        break if aq.nil?

        post "/questions/#{aq.id}/answer", params: { value: "42" }
      end

      assignment.reload.assignment_questions.size.should eq(Placement::QUESTION_COUNT)
      response.should redirect_to(placement_path(assignment))

      get placement_path(assignment)
      response.should have_http_status(:ok)
      response.body.should include(I18n.t("placement.kicker"))
      response.body.should include(RatingBand.new(student.reload.elo).name)
    end

    it "offers the session on the home page until it has been sat" do
      sign_in student
      get "/calendar"
      response.body.should include(I18n.t("placement.cta_title"))

      sit_placement(student, level: 1100)
      get "/calendar"
      response.body.should_not include(I18n.t("placement.cta_title"))
    end

    it "comes back to the question a child closed the tab on" do
      sign_in student
      post "/placements"
      assignment = student.assignments.placement.sole
      post "/questions/#{assignment.assignment_questions.first.id}/answer", params: { value: "42" }

      post "/placements"

      student.assignments.placement.count.should eq(1)
      response.should redirect_to(question_path(assignment.reload.next_assignment_question))
    end

    it "keeps the shrug, which is how a child says a topic is unmet" do
      sign_in student
      post "/placements"
      aq = student.assignments.placement.last.assignment_questions.first

      get "/questions/#{aq.id}"
      response.body.should include(I18n.t("answers.not_taught"))
      response.body.should_not match(/hidden[^>]*>\s*<form[^>]*#{Regexp.escape(question_skip_path(aq))}/m)
    end

    it "is not something a parent can sit" do
      parent = create(:user, role: :parent, verified_at: Time.current)

      sign_in parent
      post "/placements"

      response.should redirect_to("/parents/children")
    end
  end
end
