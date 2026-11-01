require "rails_helper"

# „Пробен изпит" (MockExam): an exam's topics at the exam's difficulty, timed,
# no help and no verdicts until the end, scored out of the whole paper.
describe "A mock exam", type: :request do
  let(:logic) { Topic.create!(name: "Логически задачи", parent: Topic.create!(name: "Логика")) }
  let(:student) { create(:user, elo: 1200, placed_at: Time.current) }
  let(:exam) { competition_event(slug: "test-nvo", kind: "exam", short: "НВО", grades: [ 7, 7 ]) }

  before do
    stub_calendar(exam)
    range = exam.elo_range
    30.times do |index|
      create(:question, answer: "42", elo: range.begin + index * 20,
                        text: "Задача #{Array.new(8) { ("a".."z").to_a.sample }.join}").topics << logic
    end
    sign_in student
  end

  def start!
    post competition_mock_path(exam.slug)
    student.assignments.order(:id).last
  end

  it "sets a paper of the exam's topics, easiest first, across its difficulty" do
    paper = start!
    paper.should be_mock
    rows = paper.assignment_questions.order(:position).map(&:question)
    rows.size.should eq(MockExam::FORMATS["test-nvo"].questions)
    rows.map(&:elo).should eq(rows.map(&:elo).sort)
    rows.map(&:elo).max.should be > rows.map(&:elo).min + 200
  end

  it "says nothing per answer, and ends on the result when the time is up" do
    paper = start!
    first, second = paper.assignment_questions.order(:position).first(2)

    post "/questions/#{first.id}/answer", params: { value: "42" }, headers: { "Accept" => "application/json" }
    response.parsed_body["verdict"].should be_nil
    response.parsed_body["redirect"].should eq(question_path(second))

    travel_to(MockExam.deadline(paper) + 1.second) do
      get question_path(second)
      response.should redirect_to(assignment_summary_path(paper))
      paper.reload.completed_at.should be_present

      get assignment_summary_path(paper)
      result = MockExam.result(paper)
      result.correct.should eq(1)
      result.answered.should eq(1)
      result.percent.should eq((100.0 / result.total).round)
      response.body.should include(I18n.t("mock_exam.score", correct: 1, total: result.total))
      response.body.should include(I18n.t("mock_exam.unanswered", count: result.total - 1))
    end
  end

  it "takes no answer after the time" do
    paper = start!
    row = paper.assignment_questions.order(:position).first
    travel_to(MockExam.deadline(paper) + 1.minute) do
      post "/questions/#{row.id}/answer", params: { value: "42" }
      response.should redirect_to(assignment_summary_path(paper))
      row.reload.user_answer.should be_nil
    end
  end

  it "has no hints" do
    start!.hints_allowed?.should be(false)
  end

  # From the agent field test: a paper closed halfway, or left to run out
  # overnight, was lost, and pressing the button again began a new one.
  describe "a paper that is not finished" do
    it "asks before the clock starts, and carries on rather than starting again" do
      get new_competition_mock_path(exam.slug)
      response.body.should include(I18n.t("mock_exam.ready_title"), I18n.t("mock_exam.ready_go"))
      Assignment.count.should eq(0)

      paper = start!
      start!.should eq(paper)
      get new_competition_mock_path(exam.slug)
      response.body.should include("Продължи —")

      get home_path
      response.body.should include(I18n.t("unfinished.mock", name: "НВО"))
    end

    it "is scored when its clock ran out with answers in it, and dropped when it had none" do
      answered = start!
      row = answered.next_assignment_question
      post "/questions/#{row.id}/answer", params: { value: "42" }

      travel_to(2.hours.from_now) do
        StaleSessions.close!(student)
        answered.reload.completed_at.should be_present
        answered.abandoned_at.should be_nil
        MockExam.result(answered).answered.should eq(1)
        UnfinishedSessions.for(student).should be_empty
      end
    end

    it "drops a paper whose clock ran out before a single answer" do
      paper = start!
      travel_to(2.hours.from_now) { StaleSessions.close!(student) }
      Assignment.exists?(paper.id).should be(false)
    end
  end
end
