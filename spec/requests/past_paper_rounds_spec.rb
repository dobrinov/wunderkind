require "rails_helper"

describe "Past papers of several rounds a year", type: :request do
  before do
    stub_const("PastPapers::ROOT", Rails.root.join("spec/fixtures/past_rounds"))
    Topic.find_or_create_by!(name: "Текстови задачи")
    PastPapers.import_all
  end

  let(:slug) { "matematika-bez-granitsi" }
  let(:student) { create(:user, elo: 1100) }

  it "lists each round as its own paper and sits the round that was chosen" do
    sign_in student

    get competition_papers_path(slug, grade: 3)
    response.body.should include("Темата от 2025 · Есен · 3 клас", "Темата от 2025 · Пролет · 3 клас",
                                 CGI.escapeHTML(new_competition_paper_path(slug, grade: 3, year: 2025, round: "esen")))

    get new_competition_paper_path(slug, grade: 3, year: 2025, round: "esen")
    response.body.should include("Темата от 2025 · Есен · 3 клас", "2 задачи")

    post competition_papers_path(slug), params: { grade: 3, year: 2025, round: "esen" }
    assignment = student.assignments.mock.last
    [ assignment.paper_year, assignment.paper_round ].should eq([ 2025, "esen" ])

    get question_path(assignment.next_assignment_question)
    response.body.should include("Математика без граници 2025 · Есен · 3 клас · задача 1")
  end

  it "shows the round on the competition's public page" do
    get "/sastezaniya/#{slug}"
    response.body.should include("Есен", "Пролет")
  end

  it "takes an unknown round for the main one rather than a paper that does not exist" do
    sign_in student
    get new_competition_paper_path(slug, grade: 3, year: 2025, round: "autumn")
    response.body.should include("Темата от 2025 · Пролет · 3 клас")
  end
end
