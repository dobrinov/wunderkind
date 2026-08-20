require "rails_helper"

describe Ai::Budget do
  it "accumulates cost per month and enforces the cap" do
    Ai::Budget.record!(model: "claude-opus-5", input_tokens: 1_000_000, output_tokens: 100_000)

    # 1M input at $5 + 100K output at $25/M = $5.00 + $2.50 = 750 cents
    AiUsage.current.cost_cents.should eq(750)
    AiUsage.current.calls.should eq(1)
    Ai::Budget.within_budget?.should be(false) # default cap is 500 cents
  end

  it "stays within budget for small usage" do
    Ai::Budget.record!(model: "claude-haiku-4-5", input_tokens: 10_000, output_tokens: 2_000)

    AiUsage.current.cost_cents.should eq(2)
    Ai::Budget.within_budget?.should be(true)
  end
end

describe Ai::FreeTextGrader do
  let(:question) { create(:question, :free_text) }

  it "caches verdicts per normalized answer" do
    allow(Ai::Client).to receive(:complete_json).once.
      and_return({ "verdict" => "correct", "feedback" => "Браво!" })

    first = Ai::FreeTextGrader.grade(question:, answer: "Останали са 5")
    second = Ai::FreeTextGrader.grade(question:, answer: "  останали   са 5 ")

    first.should eq(second)
    FreeTextGrading.count.should eq(1)
  end

  it "clamps unknown verdicts to incorrect" do
    allow(Ai::Client).to receive(:complete_json).and_return({ "verdict" => "amazing", "feedback" => "?" })

    Ai::FreeTextGrader.grade(question:, answer: "нещо")["verdict"].should eq("incorrect")
  end
end

describe Ai::HintGenerator do
  it "stores an unreviewed hint ladder capped at three rungs" do
    question = create(:question)
    allow(Ai::Client).to receive(:complete_json).and_return({
      "hints" => [ "едно", "две", "три", "четири" ],
      "wrong_answers" => { "41" => "Забравил си единицата." }
    })

    hint = Ai::HintGenerator.call(question)

    hint.ladder.should eq(%w[едно две три])
    hint.wrong_answer_explanations.should eq({ "41" => "Забравил си единицата." })
    hint.reviewed?.should be(false)
  end
end

describe Ai::Client do
  it "degrades when no API key is configured" do
    expect { Ai::Client.complete(user: "hi") }.to raise_error(Ai::Unavailable)
  end
end
