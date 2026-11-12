require "rails_helper"

# The calculator pages (/matematika/formuli/litse-na-triagalnik). A page is a
# file in config/calculators/ plus a module in app/javascript/lib/calculators/,
# so the first half of this checks that every file is whole; the second that
# the page says its formula as text, with no script.
RSpec.describe "Calculator pages", type: :request do
  let(:leaves) { YAML.safe_load_file(Rails.root.join("db/seeds/topics.yml")).fetch("topics").values.flatten }
  let(:registry) { Rails.root.join("app/javascript/lib/calculators/index.js").read }

  describe "every calculator file" do
    Calculators.all.each do |calculator|
      context calculator.slug do
        it "is one of the pages a formula may name, and some formula names it" do
          expect(Formulas::CALCULATORS).to include(calculator.slug)
          expect(Formulas.all.map(&:calculator)).to include(calculator.slug)
        end

        it "belongs to a leaf topic and relates only to calculators" do
          expect(leaves).to include(calculator.topic_name)
          expect(calculator.related - Formulas::CALCULATORS).to be_empty
        end

        it "has its arithmetic registered under its slug" do
          expect(registry).to include(%("#{calculator.slug}":))
        end

        it "is written whole in both languages" do
          Calculators::LOCALES.each do |locale|
            content = calculator.by_locale.fetch(locale)
            expect(content.values_at("title", "lede", "why", "mistakes")).to all(be_present), "#{locale}: a missing part"
            expect(content["copy"].keys).to eq(calculator.by_locale.fetch("bg")["copy"].keys)

            calculator.modes.each do |mode|
              copy = content.dig("modes", mode.key)
              expect(copy.values_at("name", "formula", "example")).to all(be_present), "#{locale}/#{mode.key}"
              expect(copy["inputs"].keys).to match_array(mode.inputs.map(&:key)), "#{locale}/#{mode.key}: input labels"
            end
          end
        end

        it "starts every slider inside its range" do
          calculator.modes.flat_map(&:inputs).each do |input|
            expect(input.value).to be_between(input.min, input.max)
          end
        end
      end
    end
  end

  describe "the triangle's page" do
    let!(:topic) { Topic.create!(name: "Площ", parent: Topic.create!(name: "Геометрия")) }

    it "says the formula and a worked example as text" do
      get "/matematika/formuli/litse-na-triagalnik"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<h1 class=\"landing-h1 mb-4\">Лице на триъгълник</h1>")
      expect(response.body).to include("S = a · hₐ / 2", "= 84 / 2 = 42 см²", "S = √(p(p − a)(p − b)(p − c))")
      expect(response.body).not_to include("noindex")
    end

    it "shows the bank's problems that are about a triangle, not just any area" do
      6.times do |index|
        create(:question, text: "Колко е лицето на триъгълник с основа #{index + 4} см?", status: :published, elo: 1200 + index * 40,
                          explanation: "Триъгълник #{index}").topics << topic
      end
      create(:question, text: "Колко е лицето на квадрат със страна 3 см?", status: :published, elo: 1100, explanation: "Квадратът").topics << topic

      get "/matematika/formuli/litse-na-triagalnik"

      expect(response.body).to include("Триъгълник 0", "Триъгълник 5")
      expect(response.body).not_to include("Квадратът")
    end

    it "counts a multiple-choice problem once, however many options it has" do
      2.times do |index|
        create(:question, :multiple_choice, text: "Лицето на триъгълник #{index} е:", status: :published, elo: 1200 + index,
                                            explanation: "Само два #{index}").topics << topic
      end
      create(:question, text: "Колко е лицето на квадрат със страна 3 см?", status: :published, elo: 1100, explanation: "Квадратът").topics << topic

      calculator = Calculators.find("litse-na-triagalnik")

      expect(Calculators.matching_ids(calculator, topic).size).to eq(2)
      # Two is too few, so the topic's own samples stand in — the square too.
      expect(Calculators.samples(calculator).map(&:explanation)).to include("Квадратът")
    end

    it "falls back to the topic's problems when too few name the figure" do
      create(:question, text: "Колко е лицето на квадрат със страна 3 см?", status: :published, elo: 1100, explanation: "Квадратът").topics << topic

      get "/matematika/formuli/litse-na-triagalnik"

      expect(response.body).to include("Квадратът")
    end

    it "is linked from its formulas' cards and is in the sitemap" do
      get "/matematika/formuli/5-klas"
      expect(response.body).to include('href="/matematika/formuli/litse-na-triagalnik"')

      get "/sitemap.xml"
      expect(response.body).to include("/matematika/formuli/litse-na-triagalnik</loc>")
    end

    it "reads in English too" do
      I18n.with_locale(:en) { get "/matematika/formuli/litse-na-triagalnik" }

      expect(response.body).to include("Area of a triangle", "= 84 / 2 = 42 cm²")
    end
  end

  describe "the cube's problems" do
    let!(:volume) { Topic.create!(name: "Обем", parent: Topic.create!(name: "Геометрия")) }

    it "are about a cube, not every problem measured in cubic centimetres" do
      cube = create(:question, text: "Колко е обемът на куб с ръб 3 см?", status: :published, elo: 1200, explanation: "27")
      cubes = create(:question, text: "Два куба имат ръбове 2 см и 3 см.", status: :published, elo: 1210, explanation: "8 и 27")
      small = create(:question, text: "Колко кубчета с ръб 1 см изпълват кутията?", status: :published, elo: 1220, explanation: "24")
      prism = create(:question, text: "Призма има обем 60 кубически сантиметра. Колко е височината?", status: :published, elo: 1230, explanation: "5")
      [ cube, cubes, small, prism ].each { |question| question.topics << volume }

      ids = Calculators.matching_ids(Calculators.find("kub"), volume)

      expect(ids).to contain_exactly(cube.id, cubes.id, small.id)
    end
  end

  it "has no page for a calculator that is not written yet" do
    unwritten = (Formulas::CALCULATORS - Calculators.all.map(&:slug)).first
    skip "every calculator is written" if unwritten.nil?

    get "/matematika/formuli/#{unwritten}"

    expect(response).to have_http_status(:not_found)
  end
end
