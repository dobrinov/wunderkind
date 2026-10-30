require "rails_helper"

describe Attention do
  def answer!(user, question, correct:, skipped: false)
    assignment = Assignment.create!(user: user)
    row = assignment.assignment_questions.create!(question: question, position: 1)
    row.create_user_answer!(user: user, value: "1", correct: correct && !skipped, skipped: skipped, response: { "value" => "1" })
  end

  it "names a student far below the aim, or skipping much of it, and not one doing fine" do
    struggling = create(:user, name: "Ваня")
    skipping = create(:user, name: "Калин")
    fine = create(:user, name: "Ния")
    20.times do |index|
      answer!(struggling, create(:question), correct: index < 6)
      answer!(skipping, create(:question), correct: index.even?, skipped: index < 8)
      answer!(fine, create(:question), correct: index < 15)
    end

    Attention.struggling_students.map { |entry| entry.user.name }.should contain_exactly("Ваня", "Калин")
  end

  it "names a question hardly anyone gets right" do
    broken = create(:question)
    fair = create(:question)
    5.times do |index|
      answer!(create(:user), broken, correct: false)
      answer!(create(:user), fair, correct: index < 4)
    end

    Attention.hard_questions.map(&:question).should eq([ broken ])
  end
end
