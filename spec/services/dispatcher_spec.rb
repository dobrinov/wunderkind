require "rails_helper"

describe Dispatcher do
  it "aims below the student's rating, at the target success rate" do
    # Elo says a question TARGET_SUCCESS_RATE below you sits this far down.
    expected = -(400 * Math.log10(0.7 / 0.3)).round

    Dispatcher.target_offset.should eq(expected)
    Dispatcher.target_rating(1200).should eq(1200 + expected)
    Dispatcher.target_rating(10).should eq(0)
  end

  it "starts a new student on the easiest problem in the bank, not at an arbitrary rating" do
    (600..1600).step(100) { |elo| create(:question, elo:) }

    Dispatcher.starting_rating.should eq(600)
  end

  # The floor is of the pool practice actually draws from, so a draft or a
  # free-text problem sitting below everything else cannot drag a new student
  # under the bank they will be given.
  it "reads the floor off the practice pool rather than the whole table" do
    create(:question, elo: 900)
    create(:question, elo: 400, status: :draft)
    create(:question, :free_text, elo: 500)

    Dispatcher.starting_rating.should eq(900)
  end

  it "falls back to a neutral rating when the bank is empty" do
    Dispatcher.starting_rating.should eq(Dispatcher::FALLBACK_STARTING_RATING)
  end

  it "treats a student as calibrating until they have enough attempted answers" do
    user = create(:user, elo: 1200)

    Dispatcher.should be_calibrating(user)
    calibrated!(user)
    Dispatcher.should_not be_calibrating(user.reload)
  end

  # A skip is not an attempt, so shrugging through a session must not end
  # calibration — that is exactly when the dispatcher still needs to search.
  it "does not count skipped answers towards calibration" do
    user = create(:user, elo: 1200)
    assignment = Assignment.create!(user:)

    Dispatcher::CALIBRATION_ANSWERS.times do |index|
      assignment_question = assignment.assignment_questions.create!(question: create(:question), position: index + 1)
      AnswerSubmission.skip(assignment_question:, user: user.reload)
    end

    Dispatcher.should be_calibrating(user.reload)
  end

  it "builds a ladder that climbs from the student's rating" do
    rungs = Dispatcher.calibration_rungs(700, 5)

    rungs.first.should eq(700)
    rungs.last.should eq(700 + Dispatcher::CALIBRATION_CLIMB)
    rungs.each_cons(2) { |low, high| high.should be > low }
  end

  it "widens past the band rather than returning short" do
    create_list(:question, 3, elo: 3000)

    Dispatcher.pick(create(:user, elo: 1200), count: 3).size.should eq(3)
  end

  it "leaves out topics the student has said they haven't been taught" do
    deferred_topic = Topic.create!(name: "Проценти")
    other_topic = Topic.create!(name: "Събиране")
    deferred_question = create(:question, elo: 1053, topics: [ deferred_topic ])
    create_list(:question, 3, elo: 1053, topics: [ other_topic ])

    user = create(:user, elo: 1200)
    user.skill_for(deferred_topic).update!(deferred_until: 3.weeks.from_now)

    Dispatcher.pick(user, count: 3).should_not include(deferred_question)
  end

  describe "a problem type the student skipped" do
    let(:topic) { Topic.create!(name: "Събиране и изваждане") }
    let(:user) { create(:user, elo: 1200) }

    before do
      # Plenty of history on the topic, so the topic itself is never deferred
      # (AnswerSubmission::DEFERRAL_MAX_GAMES) — the case this exists for.
      user.skill_for(topic).update!(games_count: 50)
    end

    def column_sum(a, b) = create(:question, elo: 1053, topics: [ topic ], text: "Събери в стълб #{a} + #{b}.")

    def skip!(question)
      assignment = Assignment.create!(user: user)
      row = assignment.assignment_questions.create!(question: question, position: 1)
      AnswerSubmission.skip(assignment_question: row, user: user)
    end

    it "stays out in other numbers, while the rest of the topic does not" do
      skip!(column_sum(345, 278))
      same_type = [ column_sum(512, 189), column_sum(406, 397) ]
      other = create_list(:question, 3, elo: 1053, topics: [ topic ])

      picked = Dispatcher.pick(user, count: 3)

      picked.should match_array(other)
      (picked & same_type).should be_empty
      user.skill_for(topic).reload.deferred_until.should be_nil
    end

    it "comes back once the deferral lapses" do
      skip!(column_sum(345, 278))
      later = column_sum(512, 189)

      travel_to((AnswerSubmission::DEFERRAL_DAYS + 1).days.from_now) do
        Dispatcher.available_pool(user).should include(later)
      end
    end

    it "is kept out of a duel too" do
      skip!(column_sum(345, 278))
      same_type = column_sum(512, 189)
      create_list(:question, 5, elo: 1053, topics: [ topic ])

      Dispatcher.pick_shared([ user, create(:user, elo: 1200) ], count: 5).should_not include(same_type)
    end
  end

  it "aims from the topic's own rating when a topic is named" do
    topic = Topic.create!(name: "Дроби")
    user = create(:user, elo: 1200)
    user.skill_for(topic).update!(rating: 900)

    Dispatcher.rating_for(user, [ topic.id ]).should eq(900)
    Dispatcher.rating_for(user).should eq(1200)
  end
end
