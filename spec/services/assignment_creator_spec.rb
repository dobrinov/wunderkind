require 'rails_helper'

describe AssignmentCreator do
  let(:user) { create(:user, elo: 1200) }

  it 'creates an assignment with positioned questions' do
    create :question, elo: 1200
    create :question, elo: 1210

    assignment = AssignmentCreator.execute(user:, question_count: 2)

    assignment.should be_persisted
    assignment.assignment_questions.map(&:position).should eq([ 1, 2 ])
  end

  it 'extends the elo range until it finds enough questions' do
    create :question, elo: 1200
    create :question, elo: 3000

    assignment = AssignmentCreator.execute(user:, question_count: 2)

    assignment.questions.count.should eq(2)
  end

  it 'only picks published questions' do
    create :question, elo: 1200
    create :question, elo: 1200, status: :draft

    expect { AssignmentCreator.execute(user:, question_count: 2) }.
      to raise_error(AssignmentCreator::NotEnoughQuestions)
  end

  it 'filters by topic when given' do
    topic = Topic.create!(name: "Геометрия")
    in_topic = create :question, elo: 1200, topics: [ topic ]
    create :question, elo: 1200

    assignment = AssignmentCreator.execute(user:, question_count: 1, topics: [ topic ])

    assignment.questions.should eq([ in_topic ])
  end

  it 'fails if it cannot find enough questions' do
    expect { AssignmentCreator.execute(user:, question_count: 1) }.
      to raise_error(AssignmentCreator::NotEnoughQuestions)
  end
end
