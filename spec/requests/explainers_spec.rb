require "rails_helper"

# The „Обяснено просто" articles. Two halves: the pages render and are offered
# to a crawler, and every article file is whole — both locales written, a
# playground that exists, links that land — because an article is written by
# hand and a half-finished one would otherwise reach the site.
RSpec.describe "Explainer articles", type: :request do
  let(:articles) { Explainers.all }

  it "has articles to serve" do
    expect(articles.size).to be >= 1
  end

  describe "the hub" do
    it "lists every article and is open to search" do
      get "/matematika/obyasneno"

      expect(response).to have_http_status(:ok)
      articles.each { |article| expect(response.body).to include(explainer_path(article.slug)) }
      expect(response.body).not_to include("noindex")
    end
  end

  describe "an article page" do
    it "renders every article with its playgrounds, answers and structured data" do
      articles.each do |article|
        get explainer_path(article.slug)

        expect(response).to have_http_status(:ok), article.slug
        expect(response.body).to include(ERB::Util.html_escape(article.title))
        expect(response.body).to include("LearningResource")
        article.playgrounds.each do |name|
          expect(response.body).to include(%(data-controller="explainer-#{name.dasherize}")), "#{article.slug}: #{name}"
        end
        # The self-check answers are in the page, not behind a script.
        article.quiz.each { |item| expect(response.body).to include(ERB::Util.html_escape(item["answer"]).split("**").first) }
      end
    end

    it "links the topic's problems when the bank has the topic" do
      article = articles.find(&:topic_name)
      topic = Topic.create!(name: article.topic_name)

      get explainer_path(article.slug)

      expect(response.body).to include(curriculum_topic_path(topic.slug))
    end

    it "is a 404 for an article that does not exist" do
      get "/matematika/obyasneno/nyama-takava"

      expect(response).to have_http_status(:not_found)
    end
  end

  it "puts the hub and every article in the sitemap" do
    get "/sitemap.xml"

    expect(response.body).to include(explainers_path)
    articles.each { |article| expect(response.body).to include(explainer_path(article.slug)) }
  end

  describe "the article files" do
    let(:topics) { YAML.safe_load_file(Rails.root.join("db/seeds/topics.yml")).fetch("topics").values.flatten }
    let(:index_js) { Rails.root.join("app/javascript/controllers/index.js").read }

    it "are whole in every locale" do
      articles.each do |article|
        Explainers::LOCALES.each do |locale|
          content = article.by_locale[locale]
          where = "#{article.slug} (#{locale})"

          expect(content).to be_present, where
          %w[title lede seo_title seo_description].each { |key| expect(content[key]).to be_present, "#{where}: #{key}" }
          # The layout appends the brand to every title, so a title that carries
          # it read "… | Wunderkind | Wunderkind"; and a search result cuts a
          # description off at about 160 characters.
          expect(content["seo_title"]).not_to include("Wunderkind"), where
          expect(content["seo_description"].length).to be <= 160, "#{where}: #{content['seo_description'].length} chars"
          expect(Array(content["summary"]).size).to be >= 2, where
          expect(Array(content["sections"])).to be_present, where
          expect(Array(content["traps"]).size).to be >= 2, where
          expect(Array(content["quiz"]).size).to be >= 2, where
          content["quiz"].each { |item| expect(item.values_at("question", "answer")).to all(be_present), where }
          # Every playground is placed in a section, and has its copy in this locale.
          placed = content["sections"].filter_map { |section| section["playground"] }
          expect(placed.sort).to eq(article.playgrounds.sort), where
          article.playgrounds.each { |name| expect(content.dig("playgrounds", name)).to be_present, "#{where}: #{name}" }
        end
        # The locales offer the same playground strings, so a label cannot be
        # missing in one language only.
        bg, en = article.by_locale.values_at("bg", "en")
        article.playgrounds.each do |name|
          expect(en.dig("playgrounds", name).keys.sort).to eq(bg.dig("playgrounds", name).keys.sort), "#{article.slug}: #{name}"
        end
      end
    end

    it "point at things that exist" do
      slugs = articles.map(&:slug)
      articles.each do |article|
        expect(article.slug).to match(/\A[a-z0-9-]+\z/)
        expect(topics).to include(article.topic_name), article.slug if article.topic_name
        expect(slugs).to include(*article.related), article.slug
        expect(article.grades).to be_present
        expect(1..12).to cover(article.grade_min).and cover(article.grade_max)
        article.playgrounds.each do |name|
          expect(Rails.root.join("app/views/explainers/playgrounds/_#{name}.html.erb")).to exist
          expect(Rails.root.join("app/javascript/controllers/explainers/#{name}_controller.js")).to exist
          expect(index_js).to include(%("explainer-#{name.dasherize}"))
        end
      end
    end
  end
end
