require "rails_helper"

# The public content pages. They exist because the landing page can only ever
# rank for the brand, and a parent who has not heard of Wunderkind types
# "задачи по математика за 3 клас" instead — so what matters in these tests is
# that the page carries real problems with their answers and links onward.
RSpec.describe "Curriculum pages", type: :request do
  let!(:topic) { Topic.create!(name: "Умножение и деление", parent: Topic.create!(name: "Аритметика")) }

  def publish(count, elo:, explanation: "9 + 3 = 12")
    count.times do |index|
      question = create(:question, status: :published, elo: elo + index, explanation: explanation)
      question.topics << topic
    end
  end

  describe "a grade page" do
    before { publish(Curriculum::MINIMUM_PER_TOPIC, elo: 1050) }

    it "leads with the grade in the words a parent typed" do
      get "/matematika/3-klas"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<h1 class=\"landing-h1 mb-4\">#{I18n.t("curriculum.grade.title", grade: 3)}</h1>")
      expect(response.body).to include("Задачи по математика за 3. клас с отговори")
    end

    it "shows worked problems with the answer on the page, not behind a sign-up" do
      get "/matematika/3-klas"

      expect(response.body).to include(I18n.t("curriculum.answer_label"))
      expect(response.body).to include("9 + 3 = 12")
    end

    it "links every topic it lists and the other grades" do
      get "/matematika/3-klas"

      expect(response.body).to include(curriculum_topic_path(topic.slug))
      expect(response.body).to include(curriculum_grade_path("4-klas"))
    end

    it "declares itself a Course for the rich result" do
      get "/matematika/3-klas"

      course = json_ld(response.body).find { |node| node["@type"] == "Course" }

      expect(course["teaches"]).to include(topic.name)
      expect(course["url"]).to eq("https://wunderkind.bg/matematika/3-klas")
    end

    it "puts НВО in the title of the two grades that have an exam, and not the others" do
      get "/matematika/4-klas"
      expect(response.body).to include("НВО подготовка")

      get "/matematika/3-klas"
      expect(response.body).not_to include("НВО подготовка")
    end

    it "404s on a grade the ladder does not go up to" do
      get "/matematika/9-klas"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "a topic page" do
    before { publish(Curriculum::MINIMUM_PER_TOPIC, elo: 900) }

    it "is reached by a readable, transliterated slug" do
      expect(topic.slug).to eq("umnozhenie-i-delenie")

      get "/matematika/tema/umnozhenie-i-delenie"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(topic.name)
    end

    it "spreads its samples across the difficulty range rather than taking the first six" do
      samples = Curriculum.sample_questions(elo_range: 0.., topic: topic)

      expect(samples.size).to be > 1
      expect(samples.map(&:elo).uniq.size).to eq(samples.size)
    end
  end

  describe "the shared public header" do
    before { publish(Curriculum::MINIMUM_PER_TOPIC, elo: 1050) }

    it "points the landing page's section links back at the landing page" do
      get "/matematika/4-klas"

      # A bare "#how" here targets a section that is not on this document, so
      # the link silently does nothing.
      expect(response.body).not_to include(%(href="#how"))
      expect(response.body).to include(%(href="/#how"))
      expect(response.body).to include(%(href="/#grownups"))
    end

    it "keeps them bare on the landing page, where the sections are" do
      get root_path

      expect(response.body).to include(%(href="#how"))
      expect(response.body).not_to include(%(href="/#how"))
    end

    it "still links the in-page anchor that is on the page" do
      get "/matematika/4-klas"

      expect(response.body).to include(%(href="#zadachi"))
      expect(response.body).to include(%(id="zadachi"))
    end
  end

  describe "the hub" do
    before { publish(Curriculum::MINIMUM_PER_TOPIC, elo: 1000) }

    it "links every grade and every topic with problems behind it" do
      get "/matematika"

      expect(response.body).to include(curriculum_grade_path("1-klas"))
      expect(response.body).to include(curriculum_grade_path("7-klas"))
      expect(response.body).to include(curriculum_topic_path(topic.slug))
    end
  end

  def json_ld(body)
    body.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).map { |match| JSON.parse(match.first) }
  end
end
