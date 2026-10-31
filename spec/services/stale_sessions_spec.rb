require "rails_helper"

describe StaleSessions do
  let(:student) { create(:user, elo: 1200) }
  let(:questions) { Array.new(3) { create(:question, answer: "42") } }

  def session(kind: :practice, created_at: 3.days.ago)
    assignment = Assignment.create!(user: student, kind: kind, created_at: created_at)
    questions.each_with_index { |question, index| assignment.assignment_questions.create!(question: question, position: index + 1) }
    assignment
  end

  def answer(assignment, at:)
    aq = assignment.next_assignment_question
    travel_to(at) { AnswerSubmission.call(assignment_question: aq, user: student, raw: { value: "42" }) }
  end

  it "closes a session left half-done, keeping the answers and dropping the rest" do
    assignment = session
    answer(assignment, at: 3.days.ago + 5.minutes)

    StaleSessions.close!(student)
    assignment.reload

    assignment.should be_abandoned
    assignment.completed_at.should be_within(1.second).of(3.days.ago + 5.minutes)
    assignment.assignment_questions.count.should eq(1)
    student.user_answers.count.should eq(1)
  end

  it "deletes a session that was never started" do
    assignment = session

    StaleSessions.close!(student)

    Assignment.exists?(assignment.id).should be false
  end

  it "leaves a session alone while it is still today's, or was answered in lately" do
    fresh = session(created_at: 2.hours.ago)
    resumed = session(created_at: 2.days.ago)
    answer(resumed, at: 3.hours.ago)

    StaleSessions.close!(student)

    fresh.reload.completed_at.should be_nil
    resumed.reload.completed_at.should be_nil
  end

  it "leaves placements to Placement" do
    placement = session(kind: :placement)

    StaleSessions.close!(student)

    placement.reload.completed_at.should be_nil
  end

  it "does not count a closed session towards the session badges" do
    answer(session, at: 3.days.ago)
    StaleSessions.close!(student)

    student.assignments.where.not(completed_at: nil).count.should eq(1)
    Coins.count(student, "finished").should eq(0)
  end

  describe "on the home page", type: :request do
    it "closes them when the student looks" do
      assignment = session
      answer(assignment, at: 3.days.ago)

      sign_in student
      get home_path

      assignment.reload.should be_abandoned
    end

    it "leaves them alone while an admin is looking" do
      assignment = session
      answer(assignment, at: 3.days.ago)

      sign_in create(:user, role: :admin)
      post "/impersonate/#{student.id}"
      get home_path

      assignment.reload.completed_at.should be_nil
    end
  end
end
