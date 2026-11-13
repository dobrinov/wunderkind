require "rails_helper"

# One topic in one grade (/matematika/3-klas/umnozhenie-i-delenie): the page
# that answers „текстови задачи за 2 клас". It may exist only where the grade
# page would list the topic, so nothing here promises a topic school has not
# reached or one with no problems behind it.
RSpec.describe "A topic in a grade", type: :request do
  let!(:topic) { Topic.create!(name: "Умножение и деление", parent: Topic.create!(name: "Аритметика")) }

  def publish(count, elo:, to: topic, explanation: "6 · 4 = 24")
    count.times do |index|
      create(:question, status: :published, elo: elo + index, explanation: explanation).topics << to
    end
  end

  before { publish(Curriculum::MINIMUM_PER_TOPIC, elo: 1050) }

  it "leads with the topic and the grade, and shows worked problems" do
    get "/matematika/3-klas/umnozhenie-i-delenie"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<h1 class=\"landing-h1 mb-4\">Умножение и деление за 3. клас</h1>")
    expect(response.body).to include("6 · 4 = 24", I18n.t("curriculum.answer_label"))
    expect(response.body).not_to include("noindex")
  end

  it "carries the topic's formulas for that grade and links the grade's sheet" do
    get "/matematika/3-klas/umnozhenie-i-delenie"

    expect(response.body).to include("a · (b + c) = a · b + a · c")
    expect(response.body).to include("/matematika/formuli/3-klas")
  end

  it "links the grade's strip: problems, test, formulas" do
    get "/matematika/3-klas/umnozhenie-i-delenie"

    expect(response.body).to include('href="/matematika/3-klas"', 'href="/matematika/3-klas/test"')
  end

  it "does not exist in a grade whose programme does not teach the topic" do
    publish(Curriculum::MINIMUM_PER_TOPIC, elo: 620)

    get "/matematika/1-klas/umnozhenie-i-delenie"

    expect(response).to have_http_status(:not_found)
  end

  it "does not exist where the grade's window holds too little of the topic" do
    get "/matematika/2-klas/umnozhenie-i-delenie"

    expect(response).to have_http_status(:not_found)
  end

  it "is what the grade page links its topics to, and is in the sitemap" do
    get "/matematika/3-klas"
    expect(response.body).to include('href="/matematika/3-klas/umnozhenie-i-delenie"')

    get "/sitemap.xml"
    expect(response.body).to include("/matematika/3-klas/umnozhenie-i-delenie</loc>")
  end

  it "follows a renamed topic to its new address" do
    topic.update!(previous_slugs: [ "umnozhenie" ])

    get "/matematika/3-klas/umnozhenie"

    expect(response).to redirect_to("/matematika/3-klas/umnozhenie-i-delenie")
    expect(response).to have_http_status(:moved_permanently)
  end
end
