require "rails_helper"

describe "What a child practises: a parent's focus", type: :request do
  let(:parent) { create(:user, role: :parent, name: "Ивана Петрова", verified_at: Time.current) }
  let(:child) { User.create_managed_child!(parent: parent, name: "Мира") }
  let(:fractions) { Topic.create!(name: "Дроби", parent: Topic.create!(name: "Дроби и проценти")) }
  let(:angles) { Topic.create!(name: "Ъгли", parent: Topic.create!(name: "Геометрия")) }

  # Enough problems near the child for both topics to be offered.
  before do
    child.update!(elo: 1200, placed_at: Time.current)
    [ fractions, angles ].each do |topic|
      PracticeFocuses::MINIMUM.times do |index|
        create(:question, elo: Dispatcher.target_rating(1200), text: "#{topic.name} #{index} #{SecureRandom.hex(3)}").topics << topic
      end
    end
  end

  def focus_params(topics, target: "step", reward: "")
    { mode: "focus", topic_ids: topics.map(&:id), target: target, reward: reward }
  end

  describe "the parent's tab" do
    it "offers general practice or a focus, the topics with how far the child has got, and the minutes" do
      child.skills.create!(topic: fractions, rating: 1150, games_count: 6)
      sign_in parent

      get parents_child_path(child, tab: "practice")

      response.should have_http_status(:ok)
      body = response.body
      body.should include(I18n.t("parents.children.tabs.practice"))
      body.should include(I18n.t("practice_focus.general_title"))
      body.should include(I18n.t("practice_focus.focus_title"))
      body.should include("Дроби и проценти")
      body.should include(I18n.t("practice_focus.stages.midway"))
      body.should include(I18n.t("practice_focus.stages.not_started"))
      body.should include(I18n.t("parents.daily_minutes.title"))
      body.should include(I18n.t("practice_focus.preview_general"))
    end

    it "sets a focus, and the preview and the current card say what was set" do
      sign_in parent

      patch parents_child_practice_focus_path(child), params: focus_params([ fractions ], reward: "кино в събота")

      response.should redirect_to(parents_child_path(child, tab: "practice"))
      focus = child.practice_focuses.sole
      focus.topics.should eq([ fractions ])
      focus.should be_step
      focus.reward.should eq("кино в събота")
      focus.parent.should eq(parent)

      follow_redirect!
      response.body.should include(I18n.t("practice_focus.current_title"))
      response.body.should include("Ивана те помоли да упражняваш Дроби, докато направиш една стъпка напред.")
      response.body.should include("кино в събота")
    end

    it "archives the old focus when it is changed, and saving the same thing twice changes nothing" do
      sign_in parent
      patch parents_child_practice_focus_path(child), params: focus_params([ fractions ])
      patch parents_child_practice_focus_path(child), params: focus_params([ fractions ])
      child.practice_focuses.count.should eq(1)

      patch parents_child_practice_focus_path(child), params: focus_params([ fractions, angles ], target: "mastery")

      child.practice_focuses.count.should eq(2)
      child.practice_focuses.where.not(archived_at: nil).count.should eq(1)
      PracticeFocus.active.find_by(child: child).topics.should contain_exactly(fractions, angles)
    end

    it "goes back to general practice, keeping the old focus as history" do
      sign_in parent
      patch parents_child_practice_focus_path(child), params: focus_params([ fractions ])

      patch parents_child_practice_focus_path(child), params: { mode: "general" }

      PracticeFocus.active.where(child: child).should be_empty
      child.practice_focuses.sole.should be_archived
      flash[:notice].should eq(I18n.t("practice_focus.cleared", name: "Мира"))
    end

    it "drops topics that were not offered, and refuses a focus left with none" do
      far = Topic.create!(name: "Производна", parent: Topic.create!(name: "Анализ"))
      sign_in parent

      patch parents_child_practice_focus_path(child), params: focus_params([ far ])

      child.practice_focuses.should be_empty
      flash[:alert].should eq(I18n.t("practice_focus.no_topics"))
    end

    it "says in one sentence when a chosen topic has gone thin, rather than hiding it" do
      sign_in parent
      patch parents_child_practice_focus_path(child), params: focus_params([ fractions ])
      Question.joins(:topics).where(topics: { id: fractions.id }).limit(PracticeFocuses::MINIMUM - 3).
        each { |question| question.update_column(:status, Question.statuses[:draft]) }

      get parents_child_path(child, tab: "practice")

      response.body.should include(I18n.t("practice_focus.thin", count: 1, topics: "Дроби", name: "Мира"))
      response.body.should include(%(id="focus_topic_#{fractions.id}"))
    end

    it "tells the parent when the child marks focus problems as not taught" do
      sign_in parent
      patch parents_child_practice_focus_path(child), params: focus_params([ fractions ])
      assignment = Assignment.create!(user: child, kind: :daily)
      question = fractions.questions.first
      AnswerSubmission.skip(assignment_question: assignment.assignment_questions.create!(question: question, position: 1), user: child)

      get parents_child_path(child, tab: "practice")

      response.body.should include(I18n.t("practice_focus.skipped", count: 1, name: "Мира"))
    end

    it "refuses a child who is not the parent's" do
      stranger = create(:user)
      sign_in parent

      patch parents_child_practice_focus_path(stranger), params: focus_params([ fractions ])
      response.should have_http_status(:not_found)
      get parents_child_path(stranger, tab: "practice")
      response.should have_http_status(:not_found)
      stranger.practice_focuses.should be_empty
    end

    it "is a parent's mutation: an unverified address cannot set one" do
      allow(Mailing).to receive(:enabled?).and_return(true)
      parent.update!(verified_at: nil)
      sign_in parent

      patch parents_child_practice_focus_path(child), params: focus_params([ fractions ])

      child.practice_focuses.should be_empty
    end

    it "is not a student's to set" do
      sign_in create(:user, role: :student)

      patch parents_child_practice_focus_path(child), params: focus_params([ fractions ])

      child.practice_focuses.should be_empty
    end
  end

  describe "completion" do
    it "shows a finished focus as done with its reward owed, on the child page and the family list, until it is given" do
      focus = PracticeFocuses.set!(child: child, parent: parent, topic_ids: [ fractions.id ], target: :step, reward: "кино в събота")
      child.skill_for(fractions).update!(rating: 1260, games_count: 4)
      sign_in parent

      get parents_children_path
      response.body.should include(I18n.t("practice_focus.family_done"))
      response.body.should include(I18n.t("goals.owed", count: 1))
      focus.reload.should be_completed

      get parents_child_path(child, tab: "practice")
      response.body.should include(I18n.t("practice_focus.completed_title", name: "Мира"))
      response.body.should include("кино в събота")

      patch parents_focus_reward_path(focus)
      focus.reload.reward_given_at.should be_present
      get parents_child_path(child, tab: "progress")
      response.body.should_not include(I18n.t("goals.mark_used"))
    end

    it "lets only the child's parents mark the reward given" do
      focus = PracticeFocuses.set!(child: child, parent: parent, topic_ids: [ fractions.id ], target: :step, reward: "кино")
      focus.update!(completed_at: Time.current)
      sign_in create(:user, role: :parent, verified_at: Time.current)

      patch parents_focus_reward_path(focus)

      response.should have_http_status(:not_found)
      focus.reload.reward_given_at.should be_nil
    end
  end

  describe "the child's home" do
    def open_child_home
      sign_in parent
      post switch_child_path(child)
      get home_path
    end

    it "shows who asked, the topics, the reward and the steps — never a rating" do
      PracticeFocuses.set!(child: child, parent: parent, topic_ids: [ fractions.id ], target: :step, reward: "кино в събота")
      child.skill_for(fractions).update!(rating: 1225, games_count: 3)

      open_child_home

      body = response.body
      body.should include(I18n.t("practice_focus.child_title", asker: "Ивана"))
      body.should include("Дроби")
      body.should include("кино в събота")
      body.should include(I18n.t("practice_focus.child_steps", done: 3, total: PracticeFocuses::STEPS))
      body.should_not include("1225")
      body.should_not include("1200")
    end

    it "celebrates a reached target once, then keeps only the reward owed, and the session goes back to general" do
      focus = PracticeFocuses.set!(child: child, parent: parent, topic_ids: [ fractions.id ], target: :step, reward: "кино")
      child.skill_for(fractions).update!(rating: 1300, games_count: 6)

      open_child_home
      response.body.should include(I18n.t("practice_focus.celebration_body", asker: "Ивана", topics: "Дроби"))
      response.body.should include(%(class="confetti"))
      focus.reload.celebrated_at.should be_present
      PracticeFocuses.session_topic_groups(child).should eq([])

      get home_path
      response.body.should_not include(%(class="confetti"))
      response.body.should include(I18n.t("practice_focus.celebration_reward", reward: "кино"))

      focus.give_reward!
      get home_path
      response.body.should_not include(I18n.t("practice_focus.celebration_title"))
    end

    it "shows nothing for general practice" do
      open_child_home

      response.body.should_not include(%(id="focus-card"))
    end
  end
end
