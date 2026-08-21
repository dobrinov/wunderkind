require "rails_helper"

describe Dispatcher do
  it "aims below the student's rating, at the target success rate" do
    # Elo says a question TARGET_SUCCESS_RATE below you sits this far down.
    expected = -(400 * Math.log10(0.7 / 0.3)).round

    Dispatcher.target_offset.should eq(expected)
    Dispatcher.target_rating(1200).should eq(1200 + expected)
    Dispatcher.target_rating(10).should eq(0)
  end

  it "starts a new student near the bottom of the bank, not at an arbitrary rating" do
    (600..1600).step(100) { |elo| create(:question, elo:) }

    Dispatcher.starting_rating.should be < 900
    Dispatcher.starting_rating.should be >= 600
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

  it "aims from the topic's own rating when a topic is named" do
    topic = Topic.create!(name: "Дроби")
    user = create(:user, elo: 1200)
    user.skill_for(topic).update!(rating: 900)

    Dispatcher.rating_for(user, [ topic.id ]).should eq(900)
    Dispatcher.rating_for(user).should eq(1200)
  end
end
