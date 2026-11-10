require "rails_helper"

describe Question do
  describe "#numeric_answer?" do
    it "gives the number pad to every answer that is a number, however the key printed it" do
      %w[42 0,75 3/4 −21 -21].each { |answer| build(:question, answer: answer).numeric_answer?.should be(true), answer }
      build(:question, answer: "29 640").numeric_answer?.should be(true)
    end

    it "keeps a text field for a clock time or a word, and the pad for no other kind" do
      build(:question, answer: "14:05").numeric_answer?.should be(false)
      build(:question, answer: "неделя").numeric_answer?.should be(false)
      build(:question, :multiple_choice).numeric_answer?.should be(false)
    end
  end
end
