require "rails_helper"

describe "The admin's topics", type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:student) { create(:user) }
  let!(:fractions_area) { Topic.create!(name: "Дроби и проценти") }
  let!(:fractions) { Topic.create!(name: "Дроби", parent: fractions_area) }
  let!(:decimals) { Topic.create!(name: "Десетични числа", parent: fractions_area) }
  let!(:arithmetic) { Topic.create!(name: "Аритметика") }
  let!(:multiplication) { Topic.create!(name: "Умножение и деление", parent: arithmetic) }

  before { sign_in admin }

  def question(topic, elo:, status: :published)
    create(:question, elo: elo, status: status).tap { |q| q.topics << topic }
  end

  def answer(question, skipped: false)
    assignment = Assignment.create!(user: student)
    row = assignment.assignment_questions.create!(question: question, position: 1)
    UserAnswer.create!(user: student, assignment_question: row, value: "1", correct: false,
                       skipped: skipped, response: { "value" => "1" })
  end

  describe "the tree" do
    it "shows each topic's published count, Elo range and skip share from grouped queries" do
      easy = question(fractions, elo: 800)
      question(fractions, elo: 1600)
      question(fractions, elo: 1200, status: :draft)
      question(multiplication, elo: 2000)
      answer(easy, skipped: true)
      answer(easy)
      answer(easy)
      answer(easy)

      get overseer_topics_path

      response.should have_http_status(:ok)
      body = response.body
      body.should include(I18n.t("overseer.topics.summary", areas: 2, topics: 3))
      # Two published in Дроби (the draft is not counted), a quarter skipped.
      fractions_row = body[/data-topic-id="#{fractions.id}".*?<\/a>/m]
      fractions_row.should include(">2<")
      fractions_row.should include("25%")
      # The range bar runs from 800 to 1600 on a bank scale of 800–2000.
      fractions_row.should include("left:0.0%;width:66.7%")
      # Under the minimum, and an area with a single topic, are flagged.
      fractions_row.should include(I18n.t("overseer.topics.tags.thin"))
      body.should include(I18n.t("overseer.topics.tags.single_topic"))
    end

    it "counts a question in two topics of one area once for the area" do
      shared = question(fractions, elo: 900)
      shared.topics << decimals

      TopicStats.new.for(fractions_area).published.should eq(1)
      TopicStats.new.for(fractions).published.should eq(1)
      TopicStats.new.for(decimals).published.should eq(1)
    end

    it "renders the grade view and the prerequisite map" do
      TopicPrerequisite.create!(topic: fractions, prerequisite: multiplication)
      TopicPrerequisite.create!(topic: decimals, prerequisite: fractions)

      get overseer_topics_path(view: "grades")
      response.should have_http_status(:ok)
      response.body.should include(I18n.t("curriculum.grade_name", number: 3))
      # A programme topic the tree does not have is called out.
      response.body.should include(I18n.t("overseer.topics.grades.missing"))

      get overseer_topics_path(view: "map")
      response.should have_http_status(:ok)
      body = response.body
      body.should include(I18n.t("overseer.topics.map.step", step: 3))
      body.should include(I18n.t("overseer.topics.map.needs", topics: "Дроби"))
      # Columns run left to right by depth.
      body.index(">Умножение и деление<").should be < body.index(">Дроби<")
      body.index(">Дроби<").should be < body.index(">Десетични числа<")
    end
  end

  describe "the side panel" do
    it "answers a frame request with the panel alone" do
      question(fractions, elo: 900)
      TopicPrerequisite.create!(topic: fractions, prerequisite: multiplication)
      TopicPrerequisite.create!(topic: decimals, prerequisite: fractions)
      Skill.create!(user: student, topic: fractions, mastered_at: Time.current)

      get overseer_topics_path(selected: fractions.id), headers: { "Turbo-Frame" => "topic_panel" }

      response.should have_http_status(:ok)
      body = response.body
      body.should include('<turbo-frame id="topic_panel"')
      body.should_not include(I18n.t("overseer.topics.views.map"))
      body.should include(I18n.t("overseer.topics.panel.mastered"))
      body.should include(overseer_questions_path(topic_id: fractions.id))
      body.should include(curriculum_topic_path(fractions.slug))
      body.should include(edit_overseer_topic_path(fractions))
      # Its prerequisite, itself, and what it unlocks.
      body.should include(">Умножение и деление<")
      body.should include(">Десетични числа<")
      # The explainer that names it.
      body.should include(explainer_path("kakvo-e-drob"))
    end

    it "renders inside the whole page without a frame header" do
      get overseer_topics_path(selected: fractions_area.id)

      response.should have_http_status(:ok)
      response.body.should include(I18n.t("overseer.topics.panel.topics"))
    end
  end

  describe "the editor" do
    it "renders for a new topic and an existing one" do
      get new_overseer_topic_path(parent_id: fractions_area.id)
      response.should have_http_status(:ok)

      question(fractions, elo: 900)
      get edit_overseer_topic_path(fractions)
      response.should have_http_status(:ok)
      response.body.should include(I18n.t("overseer.topics.merge"))
      response.body.should include(I18n.t("overseer.topics.delete_blocked"))
    end

    it "creates a topic with its prerequisites" do
      post overseer_topics_path, params: { topic: { name: "Проценти", parent_id: fractions_area.id,
                                                    pending_prerequisite_ids: [ "", fractions.id ] } }

      topic = Topic.find_by!(name: "Проценти")
      response.should redirect_to(overseer_topics_path(selected: topic.id))
      topic.prerequisites.should eq([ fractions ])
    end

    it "refuses a prerequisite that would close a loop, and says why" do
      TopicPrerequisite.create!(topic: decimals, prerequisite: fractions)

      get edit_overseer_topic_path(fractions)
      response.body.should include(I18n.t("overseer.topics.prerequisites_blocked", chain: "„Дроби“"))

      patch overseer_topic_path(fractions), params: { topic: { name: "Дроби", pending_prerequisite_ids: [ "", decimals.id ] } }

      response.should have_http_status(:unprocessable_content)
      response.body.should include(CGI.escapeHTML("„Десетични числа“"))
      fractions.reload.prerequisites.should be_empty
      -> { TopicPrerequisite.create!(topic: fractions, prerequisite: decimals) }.should raise_error(ActiveRecord::RecordInvalid)
    end

    it "replaces the prerequisites as a whole, and clears them" do
      TopicPrerequisite.create!(topic: decimals, prerequisite: fractions)

      patch overseer_topic_path(decimals), params: { topic: { pending_prerequisite_ids: [ "", multiplication.id ] } }
      decimals.reload.prerequisites.should eq([ multiplication ])

      patch overseer_topic_path(decimals), params: { topic: { pending_prerequisite_ids: [ "" ] } }
      decimals.reload.prerequisites.should be_empty
    end

    it "keeps an area with topics an area, and a topic with questions a topic" do
      question(fractions, elo: 900)

      patch overseer_topic_path(fractions_area), params: { topic: { parent_id: arithmetic.id } }
      response.should have_http_status(:unprocessable_content)
      fractions_area.reload.parent_id.should be_nil

      patch overseer_topic_path(fractions), params: { topic: { parent_id: "" } }
      response.should have_http_status(:unprocessable_content)
      fractions.reload.parent.should eq(fractions_area)

      # Only an area can be a parent: no third level.
      patch overseer_topic_path(decimals), params: { topic: { parent_id: fractions.id } }
      response.should have_http_status(:unprocessable_content)

      # An empty topic can move to another area, or become one.
      patch overseer_topic_path(decimals), params: { topic: { parent_id: arithmetic.id } }
      decimals.reload.parent.should eq(arithmetic)
      patch overseer_topic_path(decimals), params: { topic: { parent_id: "" } }
      decimals.reload.should be_area
    end

    it "deletes only an empty topic" do
      question(fractions, elo: 900)

      delete overseer_topic_path(fractions)
      Topic.exists?(fractions.id).should be(true)

      delete overseer_topic_path(decimals)
      response.should redirect_to(overseer_topics_path)
      Topic.exists?(decimals.id).should be(false)
    end
  end

  describe "renaming" do
    it "moves the public address and keeps the old one as a permanent redirect" do
      question(fractions, elo: 900)
      fractions.slug.should eq("drobi")

      patch overseer_topic_path(fractions), params: { topic: { name: "Обикновени дроби" } }

      fractions.reload
      fractions.slug.should eq("obiknoveni-drobi")
      fractions.previous_slugs.should eq([ "drobi" ])

      get curriculum_topic_path("drobi")
      response.should have_http_status(:moved_permanently)
      response.should redirect_to(curriculum_topic_path("obiknoveni-drobi"))

      get curriculum_topic_path("obiknoveni-drobi")
      response.should have_http_status(:ok)
    end

    it "takes an old address back when renamed back, and never hands one to another topic" do
      fractions.update!(name: "Обикновени дроби")
      Topic.create!(name: "Дроби", parent: fractions_area).slug.should eq("drobi-2")

      fractions.update!(name: "Дроби")
      fractions.slug.should eq("drobi")
      fractions.previous_slugs.should eq([ "obiknoveni-drobi" ])
    end
  end

  describe "merging" do
    it "moves questions, prerequisites, focuses and skills, then redirects the merged topic's address" do
      percents = Topic.create!(name: "Проценти", parent: fractions_area)
      in_both = question(decimals, elo: 900)
      in_both.topics << fractions
      only_decimals = question(decimals, elo: 1100)

      # Десетични числа required Умножение and unlocked Проценти; Дроби
      # required Десетични числа, which would become a self-loop.
      TopicPrerequisite.create!(topic: decimals, prerequisite: multiplication)
      TopicPrerequisite.create!(topic: percents, prerequisite: decimals)
      TopicPrerequisite.create!(topic: fractions, prerequisite: decimals)

      parent = create(:user, role: :parent)
      focus = PracticeFocus.new(child: student, parent: parent, target: :step,
                                starting_ratings: { decimals.id.to_s => 1100 })
      focus.focus_topics.build(topic: decimals)
      focus.save!

      seasoned = create(:user)
      Skill.create!(user: student, topic: decimals, rating: 1300, games_count: 30)
      Skill.create!(user: student, topic: fractions, rating: 1000, games_count: 3)
      Skill.create!(user: seasoned, topic: decimals, rating: 900, games_count: 2)
      Skill.create!(user: seasoned, topic: fractions, rating: 1250, games_count: 40)
      newcomer = create(:user)
      Skill.create!(user: newcomer, topic: decimals, rating: 1111, games_count: 1)

      post merge_overseer_topic_path(decimals), params: { into_id: fractions.id }

      response.should redirect_to(overseer_topics_path(selected: fractions.id))
      Topic.exists?(decimals.id).should be(false)
      fractions.reload

      fractions.questions.should contain_exactly(in_both, only_decimals)
      fractions.prerequisites.should eq([ multiplication ])
      percents.prerequisites.should eq([ fractions ])
      TopicPrerequisite.where(topic_id: fractions.id, prerequisite_id: fractions.id).should be_empty

      focus.reload.topics.should eq([ fractions ])
      focus.starting_ratings.should eq(fractions.id.to_s => 1100)

      # More games wins: the student keeps the merged topic's 30-game rating,
      # the seasoned student keeps their own 40-game one.
      student.skills.find_by!(topic: fractions).rating.should eq(1300)
      seasoned.skills.find_by!(topic: fractions).rating.should eq(1250)
      newcomer.skills.find_by!(topic: fractions).rating.should eq(1111)
      Skill.where(topic_id: decimals.id).should be_empty

      fractions.previous_slugs.should include("desetichni-chisla")
      get curriculum_topic_path("desetichni-chisla")
      response.should redirect_to(curriculum_topic_path(fractions.slug))
    end

    it "refuses a merge that would close a prerequisite loop" do
      # Дроби requires Умножение, which requires Десетични числа: merging
      # Десетични числа into Дроби would make Дроби require itself through
      # Умножение.
      TopicPrerequisite.create!(topic: fractions, prerequisite: multiplication)
      TopicPrerequisite.create!(topic: multiplication, prerequisite: decimals)

      post merge_overseer_topic_path(decimals), params: { into_id: fractions.id }

      response.should redirect_to(edit_overseer_topic_path(decimals))
      flash[:alert].should include("Дроби")
      Topic.exists?(decimals.id).should be(true)
    end

    it "refuses merging an area" do
      post merge_overseer_topic_path(arithmetic), params: { into_id: fractions.id }

      flash[:alert].should eq(I18n.t("overseer.topics.merge_errors.not_a_topic"))
      Topic.exists?(arithmetic.id).should be(true)
    end
  end
end
