require "rails_helper"

# /matematika/programa: the bank graded against the МОН programme and the
# competitions. The file behind it is edited by hand, so half of this guards
# the file and half the page.
RSpec.describe "Bank review page", type: :request do
  describe "config/bank_review.yml" do
    it "scores every grade from 1 to 12 exactly once" do
      expect(BankReview.grades.map(&:number)).to eq((1..12).to_a)
    end

    it "keeps every score on the 0–5 scale" do
      scores = BankReview.grades.map(&:score) + BankReview.competitions.map(&:score)

      expect(scores).to all(be_between(0, BankReview::MAX_SCORE))
    end

    it "writes every note and name in both locales" do
      localized = BankReview.grades.map(&:note) + BankReview.competitions.flat_map { |level| [ level.name, level.note ] }

      localized.each do |entry|
        expect(entry.by_locale.keys).to contain_exactly("bg", "en")
        expect(entry.by_locale.values).to all(be_present)
      end
    end

    it "dates the review and cites only links that can be opened" do
      expect(BankReview.reviewed_on).to be_a(Date)
      expect(BankReview.sources.map(&:url)).to all(start_with("https://"))
    end
  end

  it "shows every grade with its score, including the weak ones" do
    get "/matematika/programa"

    expect(response).to have_http_status(:ok)
    BankReview.grades.each do |grade|
      expect(response.body).to include(I18n.t("curriculum.coverage.grade_name", number: grade.number))
      expect(response.body).to include(ERB::Util.html_escape(grade.note.to_s))
    end
    expect(response.body).to include(I18n.t("curriculum.coverage.score_label", score: 1, max: 5))
  end

  it "lists the competitions and the documents it was measured against" do
    get "/matematika/programa"

    BankReview.competitions.each { |level| expect(response.body).to include(ERB::Util.html_escape(level.name.to_s)) }
    BankReview.sources.each { |source| expect(response.body).to include(source.url) }
  end

  it "links every reviewed grade to its practice page" do
    get "/matematika/programa"

    BankReview.grades.each { |grade| expect(response.body).to include(curriculum_grade_path("#{grade.number}-klas")) }
  end

  it "says how it was reviewed" do
    get "/matematika/programa"

    expect(response.body).to include(I18n.t("curriculum.coverage.method_body"))
  end

  it "is indexable and in the sitemap" do
    get "/matematika/programa"
    expect(response.body).not_to include("noindex")

    get "/sitemap.xml"
    expect(response.body).to include("/matematika/programa")
  end

  it "is linked from the curriculum hub" do
    get "/matematika"

    expect(response.body).to include(curriculum_coverage_path)
  end
end
