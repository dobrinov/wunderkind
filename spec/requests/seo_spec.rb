require "rails_helper"

# The app is one public page and a few dozen behind a login. What a crawler is
# allowed to keep, and what it finds when it gets there, is the whole of the
# SEO surface — so it is worth a test that the defaults hold.
RSpec.describe "SEO", type: :request do
  describe "the landing page" do
    it "carries a title and description written in the words a parent searches" do
      get root_path

      expect(response.body).to include("<title>#{I18n.t("seo.landing.title")} | Wunderkind</title>")
      expect(response.body).to include(%(name="description"))
      expect(response.body).to include("Задачи по математика")
    end

    it "declares itself indexable, canonical and shareable" do
      get root_path

      expect(response.body).to include(%(<meta name="robots" content="index, follow))
      expect(response.body).to include(%(<link rel="canonical" href="https://wunderkind.bg">))
      expect(response.body).to include(%(property="og:image"))
      expect(response.body).to include(%(name="twitter:card" content="summary_large_image"))
    end

    it "marks up the FAQ that is actually on the page" do
      get root_path

      schema = json_ld(response.body).find { |node| node["@type"] == "FAQPage" }

      expect(schema["mainEntity"].map { |entry| entry["name"] }).to include(I18n.t("landing.faq.age.q"))
      expect(response.body).to include(I18n.t("landing.faq.age.a"))
    end

    it "links the grade pages, which is the only way a crawler reaches them" do
      get root_path

      expect(response.body).to include(curriculum_grade_path("3-klas"))
      expect(response.body).to include(curriculum_path)
    end
  end

  describe "a page behind the login" do
    it "is noindex, so a crawler following it keeps no copy of the sign-in page" do
      sign_in create(:user)

      get calendar_path

      expect(response.body).to include(%(<meta name="robots" content="noindex, nofollow">))
      expect(response.body).not_to include("og:image")
    end

    it "is noindex on the sign-in page itself" do
      get sign_in_path

      expect(response.body).to include(%(content="noindex, nofollow"))
    end
  end

  describe "robots.txt" do
    it "points at the sitemap and closes the pages behind the login" do
      get "/robots.txt"

      expect(response.content_type).to start_with("text/plain")
      expect(response.body).to include("Sitemap: https://wunderkind.bg/sitemap.xml")
      expect(response.body).to include("Disallow: /overseer")
      expect(response.body).to include("Disallow: /sign-in")
    end

    it "closes the whole site on a host that is not the real one" do
      allow(Seo).to receive(:origin).and_return("https://staging.example.com")

      get "/robots.txt"

      expect(response.body).to eq("User-agent: *\nDisallow: /\n")
    end
  end

  describe "sitemap.xml" do
    it "lists the public pages and only topics with problems behind them" do
      thin = Topic.create!(name: "Куха тема", parent: Topic.create!(name: "Корен"))
      full = create_topic_with_questions("Дроби за теста", Curriculum::MINIMUM_PER_TOPIC)

      get "/sitemap.xml"

      expect(response.body).to include("<loc>https://wunderkind.bg</loc>")
      expect(response.body).to include("<loc>https://wunderkind.bg/matematika/4-klas</loc>")
      expect(response.body).to include(full.slug)
      expect(response.body).not_to include(thin.slug)
    end
  end

  def json_ld(body)
    body.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).map { |match| JSON.parse(match.first) }
  end

  def create_topic_with_questions(name, count)
    root = Topic.find_or_create_by!(name: "Корен за теста")
    topic = Topic.create!(name: name, parent: root)
    count.times { topic.questions << create(:question, status: :published, elo: 1100) }
    topic
  end
end
