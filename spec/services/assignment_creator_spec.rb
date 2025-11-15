require 'rails_helper'

describe AssignmentCreator do
  let(:user) { create(:user) }

  it 'creates an assignment' do
    create :question

    assignment = AssignmentCreator.execute(user:, question_count: 1)
    assignment.should be_present
    assignment.questions.count.should eq(1)
  end

  it 'extends elo range until it finds enough questions' do
  end

  it 'fails when engagement is not configured'
  it 'fails if it cannot find enough questions'
end
