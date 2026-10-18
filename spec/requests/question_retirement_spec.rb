require "rails_helper"

describe "Retiring a question", type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:student) { create(:user, elo: 1200) }
  let(:question) { create(:question, answer: "5", elo: 1200) }

  def session_with(*questions)
    assignment = Assignment.create!(user: student)
    questions.each_with_index { |q, index| assignment.assignment_questions.create!(question: q, position: index + 1) }
    assignment
  end

  def retire!(target = question)
    sign_in admin
    post "/overseer/questions/#{target.id}/retire"
  end

  it "takes the question out of every pool a session or duel draws from" do
    retire!

    question.reload.should be_retired
    Dispatcher.practice_pool.should_not include(question)
  end

  it "keeps it, answered, in the student's past sessions" do
    assignment = session_with(question, create(:question, answer: "7"))
    answered = assignment.assignment_questions.first
    sign_in student
    post "/questions/#{answered.id}/answer", params: { value: "5" }

    retire!

    answered.reload.question.should eq(question)
    sign_in student
    get "/questions/#{answered.id}/answer"
    response.should have_http_status(:ok)
    response.body.should include(question.body_text)
  end

  it "drops it from a session that has not reached it yet" do
    other = create(:question, answer: "7")
    assignment = session_with(other, question)

    retire!

    assignment.reload.questions.should eq([ other ])
    assignment.completed_at.should be_nil
  end

  it "finishes a session whose only unanswered question it was" do
    assignment = session_with(create(:question, answer: "7"), question)
    first = assignment.assignment_questions.first
    sign_in student
    post "/questions/#{first.id}/answer", params: { value: "7" }

    retire!

    assignment.reload.completed_at.should be_present
    assignment.questions.count.should eq(1)
  end

  it "removes a session that held nothing else" do
    assignment = session_with(question)

    retire!

    Assignment.exists?(assignment.id).should be(false)
  end

  it "replaces the question a placement was waiting on" do
    10.times { |index| create(:question, elo: 700 + index * 100) }
    assignment = Placement.start!(student)
    waiting = assignment.next_question

    retire!(waiting)

    replacement = assignment.reload.next_question
    replacement.should be_present
    replacement.should_not eq(waiting)
    assignment.assignment_questions.count.should eq(1)
  end

  it "does the same when a question is withdrawn to draft from the report queue" do
    assignment = session_with(create(:question, answer: "7"), question)
    question.reports.create!(user: student, reason: :broken)

    sign_in admin
    post "/overseer/question_reports/#{question.id}/withdraw"

    assignment.reload.questions.should_not include(question)
  end

  it "can be put back in use" do
    question.retire!

    sign_in admin
    post "/overseer/questions/#{question.id}/restore"

    question.reload.should be_published
  end

  it "only retires a published question" do
    draft = create(:question, status: :draft)

    sign_in admin
    post "/overseer/questions/#{draft.id}/retire"

    response.should have_http_status(:not_found)
    draft.reload.should be_draft
  end

  it "stays retired when its problem file is imported again" do
    topic = Topic.create!(name: "Дроби")
    question.update!(topics: [ topic ])
    question.retire!

    ProblemSeeds.import([ { "text" => question.body_text, "topic" => topic.name, "elo" => 1200, "answer" => "5" } ], { topic.name => topic })

    question.reload.should be_retired
  end

  it "is not something a student can do" do
    sign_in student
    post "/overseer/questions/#{question.id}/retire"

    question.reload.should be_published
  end
end
