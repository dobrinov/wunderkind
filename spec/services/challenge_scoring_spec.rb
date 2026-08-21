require "rails_helper"

describe ChallengeScoring do
  describe ".points" do
    it "pays nothing for a wrong answer, however fast" do
      ChallengeScoring.points(correct: false, duration_ms: 0, seconds_per_question: 30).should eq(0)
    end

    it "pays the full speed bonus for an instant correct answer" do
      ChallengeScoring.points(correct: true, duration_ms: 0, seconds_per_question: 30).
        should eq(ChallengeScoring::CORRECT_POINTS + ChallengeScoring::SPEED_POINTS)
    end

    it "pays no speed bonus for an answer that used the whole clock" do
      ChallengeScoring.points(correct: true, duration_ms: 30_000, seconds_per_question: 30).
        should eq(ChallengeScoring::CORRECT_POINTS)
    end

    it "scales the bonus with the time left" do
      ChallengeScoring.points(correct: true, duration_ms: 15_000, seconds_per_question: 30).
        should eq(ChallengeScoring::CORRECT_POINTS + ChallengeScoring::SPEED_POINTS / 2)
    end

    it "never lets speed beat correctness" do
      fast_and_wrong = 2 * ChallengeScoring.points(correct: false, duration_ms: 0, seconds_per_question: 30)
      slow_and_right = ChallengeScoring.points(correct: true, duration_ms: 30_000, seconds_per_question: 30)

      slow_and_right.should be > fast_and_wrong
    end
  end
end
