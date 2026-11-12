require "rails_helper"

# „Наръчник": the public formula sheets and articles inside the app, opened on
# the student's own grade when a birth year says what it is.
RSpec.describe "The handbook", type: :request do
  let(:student) { create(:user, role: :student) }

  # A child born this many years before the school year began is in `grade`.
  def born_for(grade) = SchoolGrade.school_year_start - 6 - grade

  it "asks a visitor to sign in" do
    get "/handbook"

    expect(response).to redirect_to("/sign-in")
  end

  it "opens on the student's own grade" do
    student.update!(birth_year: born_for(7))
    sign_in student

    get "/handbook"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("handbook.your_grade", grade: 7))
    expect(response.body).to include("(a ± b)² = a² ± 2ab + b²")
    expect(response.body).not_to include("D = b² − 4ac")
  end

  it "asks for a grade when it does not know one, and still works" do
    sign_in student

    get "/handbook"

    expect(response.body).to include(I18n.t("handbook.pick_grade"))
    expect(response.body).to include('href="/handbook?grade=5"')
  end

  it "shows whichever grade is chosen" do
    student.update!(birth_year: born_for(7))
    sign_in student

    get "/handbook", params: { grade: 8 }

    expect(response.body).to include("D = b² − 4ac", I18n.t("handbook.lead", grade: 8))
  end

  it "lists the grade's articles and opens them inside the app" do
    sign_in student

    get "/handbook", params: { grade: 8 }
    expect(response.body).to include("/handbook/explained/pitagorova-teorema")

    get "/handbook/explained/pitagorova-teorema"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(Explainers.find("pitagorova-teorema").title)
    expect(response.body).not_to include(I18n.t("landing.sign_up"))
  end

  it "offers a session on the article's topic" do
    topic = Topic.create!(name: "Питагорова теорема", parent: Topic.create!(name: "Геометрия"))
    sign_in student

    get "/handbook/explained/pitagorova-teorema"

    expect(response.body).to include(%(action="/practice/topics/#{topic.id}"))
  end

  it "offers the multiplication table to the grades learning it" do
    sign_in student

    get "/handbook", params: { grade: 3 }
    expect(response.body).to include("/handbook/times-table")

    get "/handbook", params: { grade: 9 }
    expect(response.body).not_to include("/handbook/times-table")

    get "/handbook/times-table"
    expect(response).to have_http_status(:ok)
    expect(response.body.scan(/class="times-cell"/).size).to eq(100)
  end

  it "is on the practice page and out of the crawl" do
    sign_in student
    get "/practice"
    expect(response.body).to include('href="/handbook"')

    get "/robots.txt"
    expect(response.body).to include("Disallow: /handbook")
  end

  it "is not indexable" do
    sign_in student
    get "/handbook", params: { grade: 5 }

    expect(response.body).to include("noindex")
  end
end
