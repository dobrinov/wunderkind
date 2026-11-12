require "rails_helper"

# A competition of several rounds a year (Математика без граници) files each
# round as `<year>-<round>.yml`; a file with no round is its main round, which
# is what the bank held before it held several and whose problems keep the
# source they had.
describe "Past papers of several rounds a year" do
  before do
    stub_const("PastPapers::ROOT", Rails.root.join("spec/fixtures/past_rounds"))
    Topic.find_or_create_by!(name: "Текстови задачи")
  end

  let(:slug) { "matematika-bez-granitsi" }
  let(:event) { Competitions.find(slug) }
  let(:student) { create(:user, elo: 1100) }
  let(:label) { ->(question) { ApplicationController.helpers.question_source_label(question) } }

  it "keeps a round's problems apart from the main round's, the same task number and words notwithstanding" do
    PastPapers.import_all.should eq(4)

    spring, autumn = Question.where(body_text: "Колко е 12 + 30?").partition { |question| question.source["round"].nil? }.map(&:first)
    spring.source.should_not have_key("round") # the main round's source is unchanged
    autumn.source.values_at("year", "round", "number").should eq([ 2025, "esen", "1" ])
    [ label.(spring), label.(autumn) ].should eq([ "Математика без граници 2025 · Пролет · 3 клас · задача 1", "Математика без граници 2025 · Есен · 3 клас · задача 1" ])

    expect { PastPapers.import_all }.not_to change(Question, :count)
  end

  it "lists each round as its own paper, newest first, and sits the one asked for" do
    PastPapers.import_all
    PastPapers.available(slug, grade: 3).should eq([ [ 3, 2025, 2, "esen" ], [ 3, 2025, 1, nil ] ])

    autumn = PastPapers.start!(user: student, event: event, grade: 3, year: 2025, round: "esen")
    [ autumn.paper_year, autumn.paper_round ].should eq([ 2025, "esen" ])
    autumn.assignment_questions.order(:position).map { |row| row.question.source["number"] }.should eq(%w[1 2])
    PastPapers.paper_for(autumn).round.should eq("esen")

    spring = PastPapers.start!(user: student, event: event, grade: 3, year: 2025)
    spring.should_not eq(autumn) # a running autumn paper is not the spring one
    spring.paper_round.should be_nil
    spring.assignment_questions.size.should eq(1)
  end

  it "labels ours by the round its paper was and names their figures by it" do
    PastPapers.import_all
    ours = Question.find_by!(body_text: "Колко е 6 · 5?")
    ours.source.values_at("kind", "round", "level").should eq([ "modelled", "esen", "easy" ])
    label.(ours).should eq("По модела на задача 2 · Математика без граници 2025 · Есен, 3 клас")
    PastPapers.figure_file("2025-esen", "2", "easy").should eq("fig-2025-esen-2-easy.png")
  end

  it "refuses a file whose suffix is not a round, rather than file a paper nobody can link to" do
    expect { PastPapers.split_stem("2025-autumn") }.to raise_error(ArgumentError, /unknown round/)
    PastPapers.round("autumn").should be_nil
    PastPapers.round("esen").should eq("esen")
  end
end
