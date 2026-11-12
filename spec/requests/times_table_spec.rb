require "rails_helper"

# The multiplication table. The table and every row are in the page as text,
# because that is what gets printed and what a search for „таблицата на 7"
# has to find; the scripts only add to it.
RSpec.describe "The multiplication table", type: :request do
  it "carries the whole table as a table" do
    get "/matematika/tablitsa-za-umnozhenie"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<h1 class=\"landing-h1 mb-4\">#{I18n.t("times_table.title")}</h1>")
    expect(response.body.scan(/class="times-cell"/).size).to eq(100)
    expect(response.body).to include(">56</button>", ">100</button>")
  end

  it "writes every row out, so one row can be found and printed" do
    get "/matematika/tablitsa-za-umnozhenie"

    expect(response.body).to include(I18n.t("times_table.rows.heading", row: 7))
    expect(response.body).to include("7 × 8 = <span class=\"font-black text-ink-900\">56</span>")
  end

  it "is indexable and in the sitemap" do
    get "/matematika/tablitsa-za-umnozhenie"
    expect(response.body).not_to include("noindex")

    get "/sitemap.xml"
    expect(response.body).to include("/matematika/tablitsa-za-umnozhenie</loc>")
  end

  it "links to the topic's problems when the topic exists" do
    Topic.create!(name: "Умножение и деление", parent: Topic.create!(name: "Аритметика"))

    get "/matematika/tablitsa-za-umnozhenie"

    expect(response.body).to include("/matematika/tema/umnozhenie-i-delenie")
  end

  it "reads in English too" do
    get "/matematika/tablitsa-za-umnozhenie", params: { locale: "en" }

    expect(response).to have_http_status(:ok)
  end
end
