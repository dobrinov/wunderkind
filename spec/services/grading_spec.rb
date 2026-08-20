require "rails_helper"

describe Grading do
  describe "multiple choice" do
    let(:question) { create(:question, :multiple_choice) }
    let(:correct_option) { question.possible_answers.find(&:correct?) }
    let(:wrong_option) { question.possible_answers.reject(&:correct?).first }

    it "grades a correct selection" do
      result = Grading.grade(question:, raw: { selected_ids: [ correct_option.id.to_s ] })

      result.correct.should be(true)
      result.response.should eq({ "selected_ids" => [ correct_option.id ] })
      result.display_value.should eq(correct_option.value)
    end

    it "grades a wrong selection" do
      result = Grading.grade(question:, raw: { selected_ids: [ wrong_option.id.to_s ] })

      result.correct.should be(false)
    end

    it "requires the full correct set when several options are correct" do
      second = question.possible_answers.create!(value: "also right", correct: true, position: 3)

      Grading.grade(question:, raw: { selected_ids: [ correct_option.id ] }).correct.should be(false)
      Grading.grade(question:, raw: { selected_ids: [ correct_option.id, second.id ] }).correct.should be(true)
    end

    it "rejects an empty selection" do
      Grading.grade(question:, raw: { selected_ids: [] }).correct.should be(false)
    end
  end

  describe "exact value" do
    let(:question) { create(:question, answer: "3/4") }

    it "accepts any equivalent numeric form" do
      Grading.grade(question:, raw: { value: "0,75" }).correct.should be(true)
      Grading.grade(question:, raw: { value: "6/8" }).correct.should be(true)
      Grading.grade(question:, raw: { value: "0.8" }).correct.should be(false)
    end
  end

  describe "interactive" do
    let(:question) { create(:question, :interactive) }

    it "checks the widget state against the stored solution" do
      Grading.grade(question:, raw: { state: { value: 7 }.to_json }).correct.should be(true)
      Grading.grade(question:, raw: { state: { value: 6 }.to_json }).correct.should be(false)
    end

    it "handles malformed state JSON gracefully" do
      Grading.grade(question:, raw: { state: "{not json" }).correct.should be(false)
    end
  end

  describe "free text" do
    let(:question) { create(:question, :free_text) }
    let(:user) { create(:user) }

    it "grades via the AI grader and stores verdict and feedback" do
      allow(Ai::FreeTextGrader).to receive(:grade).
        and_return({ "verdict" => "correct", "feedback" => "Точно така!" })

      result = Grading.grade(question:, raw: { value: "Останали са 5 рози" }, user:)

      result.correct.should be(true)
      result.response["verdict"].should eq("correct")
      result.response["feedback"].should eq("Точно така!")
    end

    it "treats partial as incorrect for Elo but keeps the verdict" do
      allow(Ai::FreeTextGrader).to receive(:grade).
        and_return({ "verdict" => "partial", "feedback" => "Почти." })

      result = Grading.grade(question:, raw: { value: "5" }, user:)

      result.correct.should be(false)
      result.response["verdict"].should eq("partial")
    end

    it "falls back to pending review when AI is unavailable" do
      allow(Ai::FreeTextGrader).to receive(:grade).and_raise(Ai::Unavailable)

      result = Grading.grade(question:, raw: { value: "5" }, user:)

      result.correct.should be(false)
      result.response["verdict"].should eq("pending_review")
    end

    it "stops calling the AI past the daily per-student cap" do
      allow(Grading).to receive(:free_text_answers_today).and_return(Grading::FREE_TEXT_DAILY_CAP)
      expect(Ai::FreeTextGrader).not_to receive(:grade)

      Grading.grade(question:, raw: { value: "5" }, user:).response["verdict"].should eq("pending_review")
    end
  end

  describe ".correct_answer_display" do
    it "renders per answer type" do
      mc = create(:question, :multiple_choice, answer: "B")
      Grading.correct_answer_display(mc).should eq("B")

      exact = create(:question, answer: "3/4")
      Grading.correct_answer_display(exact).should eq("3/4")

      interactive = create(:question, :interactive)
      Grading.correct_answer_display(interactive).should eq("7")
    end
  end
end
