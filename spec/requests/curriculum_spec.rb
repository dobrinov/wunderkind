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
      expect(response.body).to include("<h1 class=\"landing-h1 mb-3\">#{I18n.t("curriculum.grade.title", grade: 3)}</h1>")
      expect(response.body).to include("Задачи по математика за 3. клас с отговори")
    end

    it "shows worked problems with the answer on the page, not behind a sign-up" do
      get "/matematika/3-klas"

      expect(response.body).to include(I18n.t("curriculum.answer_label"))
      expect(response.body).to include("9 + 3 = 12")
    end

    it "keeps the answer in sight and folds the solution under it, still in the HTML" do
      get "/matematika/3-klas"

      sample = Nokogiri::HTML(response.body).at_css("#zadachi li")
      expect(sample.at_css("details.sample-fold summary").text).to include(I18n.t("curriculum.solution"))
      expect(sample.at_css("details.sample-fold").text).to include("9 + 3 = 12")
      expect(sample.xpath("./p").text).to include(I18n.t("curriculum.answer_label"))
    end

    it "folds what used to be paragraphs on the way down, and keeps their text" do
      get "/matematika/3-klas"

      folds = Nokogiri::HTML(response.body).css("details.landing-fold")
      expect(folds.map { |fold| fold.at_css("summary").text.strip }).to include(I18n.t("curriculum.grade.folds.topics"))
      expect(folds.text).to include(I18n.t("curriculum.grade.topics_blurb"))
    end

    it "lists the other grades as one row, with this one marked" do
      get "/matematika/3-klas"

      page = Nokogiri::HTML(response.body)
      expect(page.at_css("main a.grade-chip[aria-current='page']").text).to eq("3")
      expect(page.css("main a.grade-chip").size).to eq(Curriculum.grades.size)
    end

    it "shows samples from more than one topic when the grade has them" do
      fractions = Topic.create!(name: "Дроби", parent: topic.parent)
      create(:question, status: :published, elo: 1060, explanation: "Половин и половин е цяло").topics << fractions

      get "/matematika/3-klas"

      expect(response.body).to include("Половин и половин е цяло")
    end

    it "links every topic it lists and the other grades" do
      get "/matematika/3-klas"

      expect(response.body).to include(curriculum_topic_path(topic.slug))
      expect(response.body).to include(curriculum_grade_path("4-klas"))
    end

    it "leaves out a topic the programme does not teach in that grade, however many problems sit in its window" do
      logarithms = Topic.create!(name: "Логаритмична функция", parent: Topic.create!(name: "Функции"))
      Curriculum::MINIMUM_PER_TOPIC.times do |index|
        create(:question, status: :published, elo: 1060 + index, explanation: "log₂ 8 = 3").topics << logarithms
      end

      get "/matematika/3-klas"

      expect(response.body).to include(curriculum_topic_path(topic.slug))
      expect(response.body).not_to include(curriculum_topic_path(logarithms.slug))
      expect(response.body).not_to include("log₂ 8 = 3")
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

    it "gives 12th grade the матура, not НВО" do
      get "/matematika/12-klas"

      expect(response.body).to include("подготовка за матурата")
      expect(response.body).to include(I18n.t("curriculum.exam.dzi.title"))
      expect(response.body).not_to include("НВО подготовка")
    end

    it "404s on a grade the ladder does not go up to" do
      get "/matematika/13-klas"

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

  # The options are drawn as the app's answer buttons, and visitors tapped them:
  # an inert <li> that looks like a button is a dead click on the page that
  # brings the most strangers in.
  describe "a multiple-choice sample" do
    before do
      Curriculum::MINIMUM_PER_TOPIC.times do |index|
        create(:question, :multiple_choice, answer: "12", elo: 900 + index, explanation: "9 + 3 = 12").topics << topic
      end
    end

    it "offers its options as buttons that know which one is right, and more problems once one is picked" do
      get "/matematika/tema/umnozhenie-i-delenie"

      page = Nokogiri::HTML(response.body)
      options = page.css("[data-controller='sample-choice'] button.choice-button")
      expect(options).not_to be_empty
      expect(options.map { |option| option["data-correct"] }.uniq).to contain_exactly("true", "false")

      more = page.at_css("[data-sample-choice-target='more']")
      expect(more["hidden"]).not_to be_nil
      expect(more.at_css("a")["href"]).to eq(sign_up_path)
    end
  end

  describe "the shared public header" do
    before { publish(Curriculum::MINIMUM_PER_TOPIC, elo: 1050) }

    # The menu used to mix anchors into the landing page with links to pages,
    # and off the landing page a bare "#how" pointed at nothing.
    it "has the same five destinations on a content page as on the landing page" do
      destinations = [ curriculum_path, exams_path, competition_calendar_path, explainers_path, for_parents_path ]

      [ root_path, "/matematika/4-klas", for_parents_path ].each do |path|
        get path

        nav = Nokogiri::HTML(response.body).at_css("header nav.site-nav")
        expect(nav.css("a").map { |link| link["href"] }).to include(*destinations), path
        expect(nav.css("a[href^='#'], a[href^='/#']")).to be_empty, path
      end
    end

    it "puts every grade and every exam in the menu" do
      get "/matematika/4-klas"

      hrefs = Nokogiri::HTML(response.body).css("header nav.site-nav a").map { |link| link["href"] }
      expect(hrefs).to include(*Curriculum.grades.map { |grade| curriculum_grade_path(grade.slug) })
      expect(hrefs).to include(*Competitions.exams.map { |exam| exam_page_path(exam.slug) })
    end

    it "marks the section the page is under" do
      get "/matematika/4-klas"
      expect(Nokogiri::HTML(response.body).at_css("header [aria-current]").text).to include(I18n.t("landing.nav.curriculum"))

      get for_parents_path
      expect(Nokogiri::HTML(response.body).at_css("header [aria-current]").text).to include(I18n.t("landing.nav.grownups"))
    end

    it "has a menu button for the widths where the row does not fit" do
      get "/matematika/4-klas"

      button = Nokogiri::HTML(response.body).at_css("header button[data-site-nav-target='button']")
      expect(button["aria-label"]).to eq(I18n.t("landing.nav.menu"))
      expect(button["aria-expanded"]).to eq("false")
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
