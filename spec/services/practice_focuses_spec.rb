require "rails_helper"

RSpec.describe PracticeFocuses do
  let(:parent) { create(:user, role: :parent, name: "Ивана Петрова") }
  let(:child) { create(:user, elo: 1200, placed_at: Time.current) }
  let(:fractions_root) { Topic.create!(name: "Дроби и проценти") }
  let(:fractions) { Topic.create!(name: "Дроби", parent: fractions_root) }
  let(:angles) { Topic.create!(name: "Ъгли", parent: Topic.create!(name: "Геометрия")) }
  let(:target) { Dispatcher.target_rating(child.elo) }

  before { parent.parent_links.create!(child: child) }

  def publish(topic, count, elo:)
    Array.new(count) do |index|
      create(:question, elo: elo, text: "Задача #{index} за #{topic.name} #{SecureRandom.hex(4)}").tap { |question| question.topics << topic }
    end
  end

  def focus_on(*topics, target: :step, reward: nil)
    PracticeFocuses.set!(child: child, parent: parent, topic_ids: topics.map(&:id), target: target, reward: reward)
  end

  describe "the daily session under a focus" do
    it "draws only from the focus topics while they can fill it" do
      on_focus = publish(fractions, 30, elo: target)
      publish(angles, 30, elo: target)
      focus_on(fractions)

      assignment = DailyPractice.execute(user: child)

      assignment.questions.size.should be >= DailyPractice::MIN_QUESTIONS
      assignment.questions.should all(be_in(on_focus))
      assignment.should be_daily
      assignment.should be_measured
      assignment.should be_hints_allowed
      assignment.should be_skippable
    end

    it "includes the topics under a focus topic" do
      leaf = Topic.create!(name: "Смесени дроби", parent: fractions)
      under = publish(leaf, 30, elo: target)
      publish(angles, 30, elo: target)
      focus_on(fractions)

      DailyPractice.execute(user: child).questions.should all(be_in(under))
    end

    it "tops up with general practice when the focus topics run out near the child, rather than failing" do
      on_focus = publish(fractions, 3, elo: target)
      general = publish(angles, 30, elo: target)
      focus_on(fractions)

      questions = SessionComposer.execute(user: child, question_count: 10, kind: :daily,
                                          focus: PracticeFocuses.session_topic_groups(child)).questions

      questions.size.should eq(10)
      (questions & on_focus).size.should eq(3)
      (questions - on_focus).should all(be_in(general))
    end

    # The focus half stops at REACH and leaves the rest to the ordinary mix,
    # whatever that mix then chooses — the focus is not a reason to serve them.
    it "never reaches far off the child's level for a focus topic" do
      far = publish(fractions, 30, elo: target + PracticeFocuses::REACH + 400)
      publish(angles, 30, elo: target)
      focus_on(fractions)

      Dispatcher.pick(child, count: 5, topic_ids: [ fractions.id ], reach: PracticeFocuses::REACH).should be_empty
      Dispatcher.pick(child, count: 5, topic_ids: [ fractions.id ]).should all(be_in(far))

      SessionComposer.execute(user: child, question_count: 8, kind: :daily,
                              focus: PracticeFocuses.session_topic_groups(child)).questions.size.should eq(8)
    end

    it "aims at the child's rating in each focus topic" do
      child.skills.create!(topic: fractions, rating: 1600, games_count: 20)
      easy = publish(fractions, 15, elo: Dispatcher.target_rating(1200))
      right = publish(fractions, 15, elo: Dispatcher.target_rating(1600))
      focus_on(fractions)

      questions = SessionComposer.execute(user: child, question_count: 6, kind: :daily,
                                          focus: PracticeFocuses.session_topic_groups(child)).questions

      questions.should all(be_in(right))
      (questions & easy).should be_empty
    end

    it "spends the session on the topics still short of their target" do
      on_fractions = publish(fractions, 20, elo: target)
      publish(angles, 20, elo: target)
      focus_on(fractions, angles)
      child.skills.create!(topic: angles, rating: 1300, games_count: 5)

      PracticeFocuses.session_topic_groups(child).should eq([ [ fractions.id ] ])
      SessionComposer.execute(user: child, question_count: 6, kind: :daily,
                              focus: PracticeFocuses.session_topic_groups(child)).questions.should all(be_in(on_fractions))
    end

    it "is general practice when there is no focus" do
      PracticeFocuses.session_topic_groups(child).should eq([])
    end
  end

  describe "completion, read off the skills" do
    it "completes a step focus once every topic has risen a step from where it was set" do
      child.skills.create!(topic: fractions, rating: 1100, games_count: 4)
      focus = focus_on(fractions)
      focus.starting_ratings.should eq(fractions.id.to_s => 1100)

      child.skills.find_by(topic: fractions).update!(rating: 1149)
      PracticeFocuses.refresh!(child).should eq(focus)
      focus.reload.completed_at.should be_nil

      child.skills.find_by(topic: fractions).update!(rating: 1150)
      PracticeFocuses.refresh!(child).should be_nil
      focus.reload.completed_at.should be_present
    end

    it "measures a topic the child had never met from their overall rating" do
      focus = focus_on(angles)

      focus.starting_ratings.should eq(angles.id.to_s => 1200)
      child.skill_for(angles).update!(rating: 1260, games_count: 3)
      PracticeFocuses.progress(focus).should be_complete
    end

    it "completes a mastery focus by the app's own mastery stamp, and only then" do
      child.skills.create!(topic: fractions, rating: 1450, games_count: 9)
      focus = focus_on(fractions, target: :mastery)

      PracticeFocuses.refresh!(child).should eq(focus)
      child.skills.find_by(topic: fractions).update!(games_count: 10, mastered_at: Time.current)

      PracticeFocuses.refresh!(child).should be_nil
      focus.reload.should be_completed
      PracticeFocuses.session_topic_groups(child).should eq([])
    end

    it "refuses a mastery focus on topics that are already mastered" do
      child.skills.create!(topic: fractions, rating: 1450, games_count: 12, mastered_at: Time.current)

      expect { focus_on(fractions, target: :mastery) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "stores nothing but the stamp" do
      focus = focus_on(fractions)
      PracticeFocuses.refresh!(child)

      focus.reload.attributes.keys.should_not include("progress")
      focus.completed_at.should be_nil
    end
  end

  describe ".set!" do
    it "archives the focus in play rather than editing it, and keeps it" do
      first = focus_on(fractions, reward: "кино")
      second = focus_on(angles)

      first.reload.should be_archived
      second.should be_active
      child.practice_focuses.count.should eq(2)
      PracticeFocus.active.where(child: child).should eq([ second ])
    end

    it "clears a finished focus off the page when the next is set, without cancelling its reward" do
      finished = focus_on(fractions, reward: "кино")
      finished.update!(completed_at: Time.current)

      focus_on(angles)

      finished.reload.should be_archived
      finished.should be_reward_owed
      PracticeFocuses.current(child).topics.should eq([ angles ])
    end

    it "keeps where a topic started when it stays in the focus under the same target" do
      child.skills.create!(topic: fractions, rating: 1100, games_count: 4)
      focus_on(fractions, reward: "кино")
      child.skills.find_by(topic: fractions).update!(rating: 1130)

      focus_on(fractions, reward: "кино в събота").starting_ratings.should eq(fractions.id.to_s => 1100)
      focus_on(fractions, target: :mastery).starting_ratings.should eq(fractions.id.to_s => 1130)
    end

    it "refuses a focus with no topics, or too many" do
      expect { PracticeFocuses.set!(child: child, parent: parent, topic_ids: [], target: :step) }.to raise_error(ActiveRecord::RecordInvalid)

      topics = Array.new(PracticeFocus::MAX_TOPICS + 1) { |index| Topic.create!(name: "Тема #{index}") }
      expect { focus_on(*topics) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "lets the database hold only one focus in play per child" do
      focus_on(fractions)

      expect {
        PracticeFocus.create!(child: child, parent: parent, target: :step, focus_topics: [ PracticeFocusTopic.new(topic: angles) ])
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe ".offer" do
    it "offers leaf topics with enough problems near the child, grouped under their root" do
      publish(fractions, PracticeFocuses::MINIMUM, elo: target)
      publish(angles, PracticeFocuses::MINIMUM, elo: target + PracticeFocuses::REACH + 100)

      offer = PracticeFocuses.offer(child)

      offer.map { |group| group.root.name }.should eq([ "Дроби и проценти" ])
      offer.first.entries.map(&:topic).should eq([ fractions ])
    end

    it "keeps a topic of the focus in play on the list after it has gone thin" do
      PracticeFocuses.offer(child, keep: [ angles.id ]).flat_map { |group| group.entries.map(&:topic) }.should eq([ angles ])
    end

    it "says where the child stands in each topic" do
      PracticeFocuses.stage(nil).should eq(:not_started)
      PracticeFocuses.stage(Skill.new(rating: 900, games_count: 2)).should eq(:started)
      PracticeFocuses.stage(Skill.new(rating: 1150, games_count: 6)).should eq(:midway)
      PracticeFocuses.stage(Skill.new(rating: 1380, games_count: 9)).should eq(:almost)
      PracticeFocuses.stage(Skill.new(rating: 1300, games_count: 3)).should eq(:started)
      PracticeFocuses.stage(Skill.new(rating: 1450, games_count: 12, mastered_at: Time.current)).should eq(:mastered)
    end
  end

  it "counts the focus problems the child marked as not taught since the focus was set" do
    question = publish(fractions, 1, elo: target).first
    focus = focus_on(fractions)
    assignment = Assignment.create!(user: child, kind: :daily)
    aq = assignment.assignment_questions.create!(question: question, position: 1)

    AnswerSubmission.skip(assignment_question: aq, user: child)

    PracticeFocuses.skipped_count(focus).should eq(1)
  end

  it "names the parent who asked by their first name" do
    PracticeFocuses.asked_by(focus_on(fractions)).should eq("Ивана")
  end
end
