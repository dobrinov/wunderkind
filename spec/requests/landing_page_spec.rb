require "rails_helper"

# The landing page is five sections: a problem to answer and the grades, three
# doors, how it works in three lines, the questions, and one invitation. What
# it used to say at length is on „За родители" and the hub — the second half
# of this file.
RSpec.describe "Landing page", type: :request do
  let(:bank) do
    BankStats::Snapshot.new(
      total: 19_543, explained_percent: 100,
      answer_types: { interactive: 49, exact_value: 38, multiple_choice: 13 },
      widget_kinds: 20, past_papers: 2_786, past_paper_years: 1999..2025, with_figure: 0,
      by_grade: BankStats::GRADES.index_with { 1_000 }
    )
  end

  it "renders the public page for a visitor" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("landing.hero.title"))
    expect(response.body).to include(I18n.t("landing.closing.body"))
  end

  it "reads every figure on the page off the constant that implements it" do
    get root_path

    expect(response.body).to include("#{Widgets::REGISTRY.size} вида")
    expect(response.body).to include("#{DailyPractice::DEFAULT_MINUTES} минути на ден")
    expect(response.body).to include("#{Placement::QUESTION_COUNT} задачи намират нивото")
  end

  it "offers a problem to answer, not a picture of one" do
    get root_path

    options = Nokogiri::HTML(response.body).css(".landing-peek[data-controller='sample-choice'] button.choice-button")
    expect(options.size).to eq(4)
    expect(options.select { |option| option["data-correct"] == "true" }.map(&:text)).to eq([ "15" ])

    more = Nokogiri::HTML(response.body).at_css(".landing-peek [data-sample-choice-target='more']")
    expect(more["hidden"]).not_to be_nil
    expect(more.at_css("a")["href"]).to eq(trial_path)
  end

  it "puts every grade on the first screen, above the doors" do
    get root_path

    body = response.body
    expect(body).to include(curriculum_grade_path("1-klas"), curriculum_grade_path("12-klas"))
    expect(body.index(%(class="grade-key"))).to be < body.index(I18n.t("landing.doors.title"))
  end

  it "opens a door to the exams, the competitions and the study aids" do
    get root_path

    doors = Nokogiri::HTML(response.body).css("#zashto a").map { |link| link["href"] }
    expect(doors).to include(exams_path, exam_page_path("matura"), competition_calendar_path,
                             explainers_path, formulas_path, times_table_path)
  end

  it "folds the questions to one line each, with every answer still on the page" do
    get root_path

    folds = Nokogiri::HTML(response.body).css("details.landing-fold")
    expect(folds.size).to eq(6)
    expect(folds.first.at_css("summary").text).to include(I18n.t("landing.faq.age.q"))
    expect(folds.first.text).to include(I18n.t("landing.faq.age.a"))
  end

  it "stands the minutes in for the bank's size while the bank is too small to quote" do
    get root_path

    expect(response.body).to include(I18n.t("landing.proof.line", widgets: Widgets::REGISTRY.size, minutes: DailyPractice::DEFAULT_MINUTES))
  end

  it "quotes the bank's size once it is worth quoting" do
    allow(BankStats).to receive(:current).and_return(bank)

    get root_path

    expect(response.body).to include("19 500 задачи")
  end

  it "leaves the long version to the pages it moved to" do
    allow(BankStats).to receive(:current).and_return(bank)

    get root_path

    expect(response.body).not_to include(I18n.t("landing.bank.eyebrow"))
    expect(response.body).not_to include(I18n.t("landing.duel.tags.no_effect"))
    expect(response.body).not_to include(I18n.t("landing.phone.title"))
    expect(response.body).to include(for_parents_path)
  end

  it "sends a signed-in student to their own home instead" do
    student = create(:user, role: :student)
    sign_in(student)

    get root_path

    expect(response).to redirect_to(home_path)
  end

  describe "„За родители“" do
    it "says at length what the landing page says in three lines" do
      get for_parents_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("landing.for_parents.title"))
      expect(response.body).to include(I18n.t("landing.phone.title"), I18n.t("landing.grownups.parents.title"))
    end

    it "reads its figures off the constants too" do
      get for_parents_path

      expect(response.body).to include("#{Challenge::SECONDS_PER_QUESTION} секунди")
      expect(response.body).to include("#{(Dispatcher::TARGET_SUCCESS_RATE * 100).round}%")
      expect(response.body).to include(I18n.t("landing.duel.tags.no_effect"))
      expect(response.body).to include(RatingBand.new(1356).name)
    end

    it "is indexable at its own address and in the sitemap" do
      get for_parents_path

      expect(response.body).to include(%(<meta name="robots" content="index, follow))
      expect(response.body).to include(%(<link rel="canonical" href="https://wunderkind.bg/za-roditeli">))

      Rails.cache.clear
      get "/sitemap.xml"
      expect(response.body).to include("/za-roditeli</loc>")
    end

    it "is open to a signed-in parent as well" do
      sign_in(create(:user, role: :parent))

      get for_parents_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "the bank in numbers" do
    it "is on the hub once the bank is worth quoting" do
      allow(BankStats).to receive(:current).and_return(bank)

      get curriculum_path

      expect(response.body).to include(I18n.t("landing.bank.title", count: "19 500"))
      expect(response.body).to include("2 700+")
      expect(response.body).to include(I18n.t("landing.bank.past_papers_label_years", from: 1999, to: 2025))
      expect(response.body).not_to include(I18n.t("landing.bank.figures_label"))
    end

    it "is left out while the bank is too small" do
      get curriculum_path

      expect(response.body).not_to include(I18n.t("landing.bank.eyebrow"))
    end
  end
end
