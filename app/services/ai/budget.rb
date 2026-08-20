# A hard monthly ceiling on AI spend — this is a free product, so the API bill
# is a configuration value, not a surprise. When the cap is hit, AI features
# degrade gracefully (Ai::BudgetExceeded) instead of running up cost.
module Ai
  module Budget
    DEFAULT_MONTHLY_CAP_CENTS = 500 # $5

    # Dollars per million tokens, from the current Anthropic price list.
    PRICING = {
      "claude-opus-5" => { input: 5.0, output: 25.0 },
      "claude-haiku-4-5" => { input: 1.0, output: 5.0 }
    }.freeze

    module_function

    def cap_cents
      Integer(ENV.fetch("AI_MONTHLY_BUDGET_CENTS", DEFAULT_MONTHLY_CAP_CENTS))
    end

    def within_budget?
      AiUsage.current.cost_cents < cap_cents
    end

    def record!(model:, input_tokens:, output_tokens:)
      pricing = PRICING.fetch(model.to_s) { { input: 25.0, output: 125.0 } } # unknown models assumed expensive
      cost_cents = ((input_tokens * pricing[:input] + output_tokens * pricing[:output]) / 1_000_000 * 100).ceil

      usage = AiUsage.current
      usage.update!(cost_cents: usage.cost_cents + cost_cents, calls: usage.calls + 1)
    end
  end
end
