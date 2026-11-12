require "rails_helper"

# The formula sheets. What matters is that the formulas are on the page as
# text — a sheet that needs a script or a sign-up to show a² + b² answers
# nobody's search — and that each grade and each exam has a page of its own.
RSpec.describe "Formula sheets", type: :request do
  it "puts every formula on the hub" do
    get "/matematika/formuli"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("c² = a² + b²", "S = a · hₐ / 2", "(xⁿ)′ = n · xⁿ⁻¹")
    expect(response.body).to include("<h1 class=\"landing-h1 mb-4\">#{I18n.t("formulas.index.title")}</h1>")
  end

  it "keeps a grade's sheet to what that grade has been taught" do
    get "/matematika/formuli/4-klas"

    expect(response.body).to include("P = 2 · (a + b)", "S = a · b")
    expect(response.body).not_to include("c² = a² + b²")
    expect(response.body).to include(I18n.t("seo.formulas.grade.title", grade: 4))
  end

  it "has a sheet for each exam, named for it" do
    get "/matematika/formuli/nvo-7-klas"

    expect(response.body).to include(I18n.t("formulas.nvo.title", grade: 7))
    expect(response.body).to include("(a ± b)² = a² ± 2ab + b²")
    expect(response.body).not_to include("D = b² − 4ac")

    get "/matematika/formuli/matura"

    expect(response.body).to include(I18n.t("formulas.matura.title"), "logₐ b = c  ⇔  aᶜ = b")
  end

  it "shows the example with each formula, in the page" do
    get "/matematika/formuli/7-klas"

    expect(response.body).to include("(x + 3)² = x² + 6x + 9")
  end

  it "links a topic to its problems and to its article when it has them" do
    Topic.create!(name: "Питагорова теорема", parent: Topic.create!(name: "Геометрия"))

    get "/matematika/formuli/8-klas"

    expect(response.body).to include("/matematika/tema/pitagorova-teorema")
    expect(response.body).to include("/matematika/obyasneno/pitagorova-teorema")
  end

  it "is indexable, with its own canonical address" do
    get "/matematika/formuli/nvo-10-klas"

    expect(response.body).to include("/matematika/formuli/nvo-10-klas")
    expect(response.body).not_to include("noindex")
  end

  it "answers an unknown sheet with a 404" do
    get "/matematika/formuli/13-klas"

    expect(response).to have_http_status(:not_found)
  end

  it "is in the sitemap" do
    get "/sitemap.xml"

    expect(response.body).to include("/matematika/formuli</loc>", "/matematika/formuli/matura</loc>", "/matematika/formuli/7-klas</loc>")
  end

  it "reads in English too" do
    get "/matematika/formuli/7-klas", params: { locale: "en" }

    expect(response).to have_http_status(:ok)
  end
end
