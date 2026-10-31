require "rails_helper"

describe "The end of a session", type: :request do
  let(:student) { create(:user, elo: 1200, feedback_after_answer: false) }

  def session_of(count, kind: :practice, **attributes)
    assignment = Assignment.create!(user: student, kind: kind, **attributes)
    count.times { |index| assignment.assignment_questions.create!(question: create(:question, answer: "5"), position: index + 1) }
    assignment
  end

  def answer_all(assignment, values)
    assignment.assignment_questions.zip(values).each do |assignment_question, value|
      post "/questions/#{assignment_question.id}/answer", params: { value: value }
    end
  end

  it "adds up the XP of the whole session, not only the answer that ended it" do
    assignment = session_of(3)
    sign_in student
    answer_all(assignment, %w[5 5 5])

    total = XpEvent.where(user: student).sum(:amount)
    total.should be > XpEvent.where(user: student).order(:id).last.amount
    assignment.reload.xp_earned.should eq(total)

    follow_redirect!
    response.body.should include("+#{total}</span>")
    response.body.should include(I18n.t("summary.xp_label"))
  end

  it "ticks today's streak and sends the child back to „Днес“" do
    assignment = session_of(2)
    sign_in student
    answer_all(assignment, %w[5 5])
    follow_redirect!

    response.body.should include(I18n.t("summary.streak_label", count: 1))
    response.body.should include(I18n.t("summary.streak_today"))
    response.body.should include(%(href="#{home_path}"))
    response.body.should include(I18n.t("summary.home"))
  end

  it "offers the mistakes just made, and practises only those" do
    older = session_of(1)
    older.assignment_questions.first.create_user_answer!(user: student, value: "4", correct: false, response: { "value" => "4" })

    assignment = session_of(3)
    sign_in student
    answer_all(assignment, %w[4 4 5])
    follow_redirect!

    response.body.should include(I18n.t("summary.practise_mistakes", count: 2))

    post practice_review_path, params: { assignment_id: assignment.id }
    practice = student.assignments.mistakes.last
    practice.questions.should match_array(assignment.assignment_questions.first(2).map(&:question))
  end

  it "offers no mistakes button after a clean session" do
    assignment = session_of(2)
    sign_in student
    answer_all(assignment, %w[5 5])
    follow_redirect!

    response.body.should_not include(I18n.t("summary.practise_mistakes", count: 1))
    response.body.should_not include(practice_review_path)
  end

  it "sends an unfinished session back to its next question" do
    assignment = session_of(2)
    sign_in student
    post "/questions/#{assignment.assignment_questions.first.id}/answer", params: { value: "5" }

    get assignment_summary_path(assignment)
    response.should redirect_to(question_path(assignment.assignment_questions.second))
  end

  it "sends a placement to its own result screen" do
    assignment = session_of(1, kind: :placement)
    sign_in student

    get assignment_summary_path(assignment)
    response.should redirect_to(placement_path(assignment))
  end

  it "offers another round of a competition as the primary, with the way home beside it" do
    event = Competitions.all.first
    assignment = session_of(1, kind: :competition, competition_slug: event.slug)
    sign_in student
    answer_all(assignment, %w[5])
    follow_redirect!

    response.body.should include(competition_practice_path(event.slug))
    response.body.should include(I18n.t("summary.home"))
  end

  it "shows a coin earned in the session, once" do
    assignment = session_of(1)
    sign_in student
    answer_all(assignment, %w[5])
    follow_redirect!

    response.body.should match(/#{I18n.t("coins.new")}|#{I18n.t("coins.new_many")}/)
    response.body.should include(I18n.t("coins.tracks.finished.name"))
    student.badge_awards.where(seen_at: nil).should be_empty

    get assignment_summary_path(assignment)
    response.body.should_not include("new-coin-title")
  end
end
