require "rails_helper"

describe PastPapers do
  before do
    stub_const("PastPapers::ROOT", Rails.root.join("spec/fixtures/past"))
    %w[Ред\ на\ действията Текстови\ задачи].each { |name| Topic.find_or_create_by!(name: name) }
  end

  let(:event) { Competitions.find("sofiyski-matematicheski-turnir") }
  let(:student) { create(:user, elo: 1100) }

  it "imports a paper word for word, each problem carrying where it came from" do
    PastPapers.import_all.should eq(4)

    question = Question.find_by!(body_text: "Баба ми има по равен брой котета, кучета и пилета. Общо краката на животните са 100. Колко са котетата?")
    question.source.should eq("kind" => "original", "competition" => "sofiyski-matematicheski-turnir", "grade" => 3,
                              "year" => 2024, "number" => "11", "points" => 7, "task" => "short")
    question.grading["expected"].should eq("10")

    expect { PastPapers.import_all }.not_to change(Question, :count)
  end

  it "keeps two papers' problems apart even when their words are the same" do
    PastPapers.import_all
    Question.where(body_text: "На колко е равно (2 · 0 + 2 · 4) : (2 + 0 + 2 + 4)?").map { |q| q.source["year"] }.should contain_exactly(2023, 2024)
  end

  it "lists the papers in the bank and sits one with its own clock, order and points" do
    PastPapers.import_all
    PastPapers.available(event.slug, grade: 3).should eq([ [ 3, 2024, 2 ], [ 3, 2023, 1 ] ])

    assignment = PastPapers.start!(user: student, event: event, grade: 3, year: 2024)
    assignment.should be_mock
    assignment.assignment_questions.order(:position).map { |row| row.question.source["number"] }.should eq(%w[1 11])
    MockExam.deadline(assignment).should eq(assignment.created_at + 90.minutes)

    first = assignment.assignment_questions.order(:position).first
    UserAnswer.create!(user: student, assignment_question: first, value: "1", correct: true, response: { "value" => "1" })
    result = MockExam.result(assignment)
    [ result.points, result.max_points, result.unchecked ].should eq([ 5, 12, 1 ])
  end

  it "imports ours on a paper's model, labelled by the problem it was modelled on" do
    PastPapers.import_all
    question = Question.find_by!(body_text: "На двора има по равен брой кози и кокошки. Общо краката им са 30. Колко са козите?")
    question.source.values_at("kind", "number", "level", "year").should eq([ "modelled", "11", "easy", 2024 ])
    ApplicationController.helpers.question_source_label(question).should eq("По модела на задача 11 · СМТ 2024, 3 клас")
    PastPapers.available(event.slug, grade: 3).should eq([ [ 3, 2024, 2 ], [ 3, 2023, 1 ] ]) # not part of a paper
  end

  it "labels a past paper's problem by the competition, never by where the paper was found" do
    PastPapers.import_all
    question = PastPapers.questions(event.slug, 3, 2024).first
    label = ApplicationController.helpers.question_source_label(question)

    label.should eq("СМТ 2024 · 3 клас · задача #{question.source["number"]}")
    label.should_not include("lasirane")
  end
end
