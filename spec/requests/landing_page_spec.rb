require "rails_helper"

RSpec.describe "Landing page", type: :request do
  it "renders the public page for a visitor" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("landing.hero.title"))
    expect(response.body).to include(I18n.t("landing.closing.body"))
  end

  it "reads every figure on the page off the constant that implements it" do
    get root_path

    expect(response.body).to include("#{Challenge::SECONDS_PER_QUESTION} секунди")
    expect(response.body).to include("#{Widgets::REGISTRY.size} вида")
    expect(response.body).to include("#{RatingBand::BANDS.size} нива")
    expect(response.body).to include(I18n.t("landing.duel.tags.no_effect"))
  end

  it "shows the minutes tile instead of a bank size when the bank is small" do
    get root_path

    expect(response.body).to include(I18n.t("landing.proof.minutes_label"))
  end

  it "leaves out the bank section while the bank is too small to quote" do
    get root_path

    expect(response.body).not_to include(I18n.t("landing.bank.eyebrow"))
  end

  it "shows the bank size and the bank section once the bank is worth quoting" do
    allow(BankStats).to receive(:current).and_return(
      BankStats::Snapshot.new(
        total: 19_543, explained_percent: 100,
        answer_types: { interactive: 49, exact_value: 38, multiple_choice: 13 },
        widget_kinds: 20, past_papers: 2_786, past_paper_years: 1999..2025, with_figure: 0,
        by_grade: BankStats::GRADES.index_with { 1_000 }
      )
    )

    get root_path

    expect(response.body).to include("19 500 задачи")
    expect(response.body).not_to include(I18n.t("landing.proof.minutes_label"))
    expect(response.body).to include(I18n.t("landing.bank.title", count: "19 500"))
    expect(response.body).to include("2 700+")
    expect(response.body).to include(I18n.t("landing.bank.past_papers_label_years", from: 1999, to: 2025))
    expect(response.body).not_to include(I18n.t("landing.bank.figures_label"))
    expect(response.body).to include(curriculum_grade_path("12-klas"))
  end

  it "sends a signed-in student to their own home instead" do
    student = create(:user, role: :student)
    sign_in(student)

    get root_path

    expect(response).to redirect_to(home_path)
  end
end
