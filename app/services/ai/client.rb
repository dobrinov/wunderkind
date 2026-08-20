# The single gateway for every Claude API call the app makes: checks the
# monthly budget before the call, records usage after it, and folds all
# API failure modes into Ai::Unavailable so callers degrade with one rescue.
module Ai
  Unavailable = Class.new(StandardError)
  BudgetExceeded = Class.new(Unavailable)

  # One-time generation (hints, authoring assistance) uses the capable model —
  # results are cached forever, so quality beats cost. Per-answer grading uses
  # the small model.
  GENERATION_MODEL = "claude-opus-5"
  GRADING_MODEL = "claude-haiku-4-5"

  module Client
    module_function

    def enabled?
      ENV["ANTHROPIC_API_KEY"].present?
    end

    def complete(user:, model: GENERATION_MODEL, system: nil, max_tokens: 4000)
      raise Unavailable, "ANTHROPIC_API_KEY is not configured" unless enabled?
      raise BudgetExceeded, "Monthly AI budget exhausted" unless Budget.within_budget?

      params = {
        model: model,
        max_tokens: max_tokens,
        messages: [ { role: "user", content: user } ]
      }
      params[:system_] = [ { type: "text", text: system } ] if system

      message = anthropic.messages.create(**params)
      Budget.record!(
        model: model,
        input_tokens: message.usage.input_tokens,
        output_tokens: message.usage.output_tokens
      )

      raise Unavailable, "Model declined the request" if message.stop_reason == :refusal

      message.content.find { |block| block.type == :text }&.text.to_s
    rescue Anthropic::Errors::RateLimitError => error
      raise Unavailable, "Rate limited: #{error.message}"
    rescue Anthropic::Errors::APIStatusError => error
      raise Unavailable, "API error #{error.type}: #{error.message}"
    rescue Anthropic::Errors::APIConnectionError => error
      raise Unavailable, "Connection error: #{error.message}"
    end

    # Prompts ask for bare JSON; models occasionally wrap it in a code fence.
    def complete_json(...)
      text = complete(...)
      JSON.parse(text[/\{.*\}|\[.*\]/m].to_s)
    rescue JSON::ParserError
      raise Unavailable, "Model returned unparseable JSON"
    end

    def anthropic
      @anthropic ||= Anthropic::Client.new
    end
  end
end
