require "rails_helper"

# The worksheets (/matematika/3-klas/raboten-list): paper. What matters is that
# the sheet is whole in the page — problems, a place to answer, and the key —
# and that its problems are a set of their own.
RSpec.describe "Worksheets", type: :request do
  let!(:topic) { Topic.create!(name: "Умножение и деление", parent: Topic.create!(name: "Аритметика")) }
  let(:grade) { Curriculum.grade("3-klas") }

  before do
    40.times do |index|
      create(:question, status: :published, elo: 860 + index * 7, answer: (index + 2).to_s, explanation: "Обяснение #{index}").topics << topic
    end
    12.times do |index|
      create(:question, :multiple_choice, status: :published, elo: 863 + index * 23, answer: "7", explanation: "56 : 8 = 7").topics << topic
    end
  end

  it "sets problems that the grade page and the test do not show" do
    sheet = Curriculum.worksheet_questions(grade).map(&:id)
    shown = Curriculum.sample_questions(elo_range: grade.range, grade: grade).map(&:id) + Curriculum.test_questions(grade).map(&:id)

    expect(sheet.size).to eq(Curriculum::WORKSHEET_LENGTH)
    expect(sheet & shown).to be_empty
  end

  it "is a sheet of problems with a place to answer, and a key" do
    get "/matematika/3-klas/raboten-list"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("curriculum.worksheet.grade.title", grade: 3))
    expect(response.body).to include(I18n.t("curriculum.worksheet.kicker", grade: 3), I18n.t("curriculum.worksheet.key_kicker"))
    expect(response.body.scan(/break-inside-avoid/).size).to eq(Curriculum::WORKSHEET_LENGTH * 2)
    expect(response.body).not_to include("noindex")
  end

  it "letters a multiple-choice problem's options and gives the letter in the key" do
    get "/matematika/3-klas/raboten-list"

    choice = Curriculum.worksheet_questions(grade).find(&:multiple_choice?)
    expect(choice).to be_present
    expect(response.body).to include('<span class="font-black">А)</span> 7')
    expect(response.body).to include('<span class="font-black">Б)</span> wrong')
  end

  it "keeps the solutions off the sheet" do
    get "/matematika/3-klas/raboten-list"

    expect(response.body).not_to include("Обяснение", "56 : 8 = 7")
  end

  it "has a sheet for a topic in a grade, of that topic only" do
    other = Topic.create!(name: "Дроби", parent: topic.parent)
    30.times { |index| create(:question, status: :published, elo: 870 + index * 9, text: "Дроб #{index}", explanation: "x").topics << other }

    get "/matematika/3-klas/umnozhenie-i-delenie/raboten-list"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("curriculum.worksheet.topic.title", topic: topic.name, grade: 3))
    expect(response.body).not_to include("Дроб 1")
  end

  it "does not exist for a topic the grade does not teach, or with too little to print" do
    get "/matematika/1-klas/umnozhenie-i-delenie/raboten-list"
    expect(response).to have_http_status(:not_found)

    get "/matematika/12-klas/raboten-list"
    expect(response).to have_http_status(:not_found)
  end

  it "is linked from the grade's strip and the topic's page, and is in the sitemap" do
    get "/matematika/3-klas"
    expect(response.body).to include('href="/matematika/3-klas/raboten-list"')

    get "/matematika/3-klas/umnozhenie-i-delenie"
    expect(response.body).to include('href="/matematika/3-klas/umnozhenie-i-delenie/raboten-list"')

    get "/sitemap.xml"
    expect(response.body).to include("/matematika/3-klas/raboten-list</loc>", "/matematika/3-klas/umnozhenie-i-delenie/raboten-list</loc>")
    expect(response.body).not_to include("/matematika/12-klas/raboten-list</loc>")
  end

  describe "variants" do
    it "sets other sheets from what the ones before left, the same on every load" do
      sheets = Curriculum.worksheet_sheets(grade).to_a.map { |sheet| sheet.map(&:id) }

      expect(sheets.size).to be > 1
      expect(sheets.flatten).to eq(sheets.flatten.uniq)
      expect(sheets.first).to eq(Curriculum.worksheet_questions(grade).map(&:id))
      expect(Curriculum.worksheet_questions(grade, variant: 2).map(&:id)).to eq(sheets.second)
      expect(Curriculum.worksheet_variants(grade)).to eq(sheets.size)
    end

    it "offers „Друг лист“, which leads to the next sheet and back round to the first" do
      last = Curriculum.worksheet_variants(grade)

      get "/matematika/3-klas/raboten-list"
      expect(response.body).to include(I18n.t("curriculum.worksheet.another"), 'href="/matematika/3-klas/raboten-list?list=2"')
      expect(response.body).to include(I18n.t("curriculum.worksheet.sheet_number", number: 1))

      get "/matematika/3-klas/raboten-list", params: { list: last }
      expect(response.body).to include('href="/matematika/3-klas/raboten-list"')
      expect(response.body).to include(I18n.t("curriculum.worksheet.sheet_number", number: last), "raboten-list?list=#{last}</span>")
    end

    it "shows the second sheet's own problems and key" do
      second = Curriculum.worksheet_questions(grade, variant: 2)
      first = Curriculum.worksheet_questions(grade)

      get "/matematika/3-klas/raboten-list", params: { list: 2 }

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/break-inside-avoid/).size).to eq(second.size * 2)
      expect(second.map(&:id) & first.map(&:id)).to be_empty
    end

    it "keeps the other sheets out of the index, pointing at the first" do
      get "/matematika/3-klas/raboten-list", params: { list: 2 }

      expect(response.body).to include("noindex")
      expect(response.body).to include('<link rel="canonical" href="https://wunderkind.bg/matematika/3-klas/raboten-list"')
    end

    it "has no sheet beyond the last, and none for a number that is not one" do
      get "/matematika/3-klas/raboten-list", params: { list: Curriculum.worksheet_variants(grade) + 1 }
      expect(response).to have_http_status(:not_found)

      get "/matematika/3-klas/raboten-list", params: { list: "abc" }
      expect(response).to have_http_status(:not_found)

      get "/matematika/3-klas/raboten-list", params: { list: 0 }
      expect(response).to have_http_status(:not_found)
    end
  end

  it "reads in English too" do
    I18n.with_locale(:en) { get "/matematika/3-klas/raboten-list" }

    expect(response.body).to include(I18n.t("curriculum.worksheet.key_kicker", locale: :en), '<span class="font-black">A)</span>')
  end
end
