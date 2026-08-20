require "rails_helper"

describe HomeworkCreator do
  let(:teacher) { create(:user, role: :teacher) }
  let(:students) { create_list(:user, 2) }
  let(:classroom) do
    Classroom.create!(teacher:, name: "5а").tap do |c|
      students.each { |student| c.classroom_memberships.create!(user: student) }
    end
  end

  it "creates the homework and one assignment per student" do
    questions = create_list(:question, 3, elo: 1200)

    homework = HomeworkCreator.execute(
      assigner: teacher, classroom:, students:,
      title: "Дроби", due_at: 3.days.from_now,
      question_ids: questions.map(&:id)
    )

    homework.should be_persisted
    homework.questions.count.should eq(3)
    homework.assignments.count.should eq(2)
    homework.assignments.each do |assignment|
      assignment.kind.should eq("homework")
      assignment.questions.should match_array(questions)
      assignment.assignment_questions.map(&:position).should eq([ 1, 2, 3 ])
    end
  end

  it "auto-fills published questions near the students' level" do
    students.each { |student| student.update!(elo: 1000) }
    near = create(:question, elo: 1020)
    create(:question, elo: 2800)

    homework = HomeworkCreator.execute(
      assigner: teacher, classroom:, students:,
      title: "Авто", due_at: 3.days.from_now, auto_count: 1
    )

    homework.questions.should eq([ near ])
  end

  it "lets the assigner use their private questions but not someone else's" do
    own_private = create(:question, status: :private_library, author: teacher)
    foreign_private = create(:question, status: :private_library, author: create(:user, role: :teacher))

    homework = HomeworkCreator.execute(
      assigner: teacher, classroom:, students:,
      title: "Лични", due_at: 3.days.from_now,
      question_ids: [ own_private.id, foreign_private.id ]
    )

    homework.questions.should eq([ own_private ])
  end

  it "raises without students or questions" do
    expect {
      HomeworkCreator.execute(assigner: teacher, students: [], title: "x", due_at: 1.day.from_now)
    }.to raise_error(HomeworkCreator::NoStudents)

    expect {
      HomeworkCreator.execute(assigner: teacher, students:, title: "x", due_at: 1.day.from_now)
    }.to raise_error(HomeworkCreator::NoQuestions)
  end
end
