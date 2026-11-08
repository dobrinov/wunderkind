require "rails_helper"

describe "Admin: competitions and their editions", type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:smt) { Competition.find_by!(slug: "sofiyski-matematicheski-turnir") }

  before { sign_in admin }

  it "lists every competition with its next date and what needs attention" do
    travel_to Date.new(2026, 11, 20) do # the 2026 tournament is over, no 2027 date yet
      get overseer_competitions_path
      response.body.should include("Софийски математически турнир", I18n.t("overseer.competitions.flags.no_next_date"))
    end
  end

  it "makes next year's edition from this year's, every date marked approximate" do
    expect { post next_edition_overseer_competition_path(smt.slug) }.to change { smt.editions.count }.by(1)

    edition = smt.editions.reload.last
    edition.year.should eq(smt.editions.where.not(id: edition.id).maximum(:year) + 1)
    edition.rounds.map(&:approximate).uniq.should eq([ true ])
    edition.rounds.first.date.should eq(smt.editions.find_by(year: edition.year - 1).rounds.first.date.next_year)
    response.should redirect_to(edit_overseer_competition_edition_path(smt.slug, edition))
  end

  it "edits an edition's rounds and its own format, and the calendar reads them" do
    edition = smt.editions.find_by!(year: 2026)
    round = edition.rounds.first

    patch overseer_competition_edition_path(smt.slug, edition), params: { competition_edition: {
      year: 2026, format: { bg: "13 задачи, 2 часа.", en: "13 problems, 2 hours." },
      rounds_attributes: { "0" => { id: round.id, date: "2026-11-14", approximate: "0", name: { bg: "Турнир", en: "Tournament" } } }
    } }

    Current.reset
    event = Competitions.find(smt.slug)
    event.edition(2026).rounds.map(&:date).should eq([ Date.new(2026, 11, 14) ])
    event.edition(2026).format.to_s.should eq("13 задачи, 2 часа.")
  end

  it "keeps the competition's own fields valid in both languages" do
    patch overseer_competition_path(smt.slug), params: { competition: { name: { bg: "СМТ", en: "" } } }
    response.status.should eq(422)
  end

  it "is for admins only" do
    sign_in create(:user)
    get overseer_competitions_path
    response.should redirect_to(root_path)
  end
end

describe "Competition editions", type: :request do
  it "shows the past years of a competition on its public page, with their papers" do
    stub_const("PastPapers::ROOT", Rails.root.join("spec/fixtures/past"))
    %w[Ред\ на\ действията Текстови\ задачи].each { |name| Topic.find_or_create_by!(name: name) }
    PastPapers.import_all

    get "/sastezaniya/sofiyski-matematicheski-turnir"
    response.body.should include(I18n.t("competitions.show.past_editions", name: "СМТ"), "2024", I18n.t("competitions.show.papers.title", grade: 3))
    # Each year opens its own paper, not the grade's list.
    response.body.should include(new_competition_paper_path("sofiyski-matematicheski-turnir", grade: 3, year: 2023).gsub("&", "&amp;"))
  end
end
