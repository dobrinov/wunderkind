# The curated interactive widget registry. Each widget has a server-side checker
# (the correct answer never reaches the client) and a display projection used to
# show the student's response back to them.
module Widgets
  Definition = Struct.new(:key, :checker, :display, keyword_init: true)

  REGISTRY = {
    "number_line" => Definition.new(
      key: "number_line",
      checker: ->(solution, state, _params) {
        value = state["value"]
        return false if value.nil?

        tolerance = solution.fetch("tolerance", 0).to_f
        (value.to_f - solution["value"].to_f).abs <= tolerance
      },
      display: ->(state, _params) { state["value"].to_s }
    ),
    "ordering" => Definition.new(
      key: "ordering",
      checker: ->(solution, state, _params) {
        state["order"].present? && state["order"].map(&:to_s) == solution["order"].map(&:to_s)
      },
      display: ->(state, params) {
        labels = Array(params["items"]).index_by { |item| item["id"].to_s }
        Array(state["order"]).map { |id| labels.dig(id.to_s, "label") || id }.join(" → ")
      }
    ),
    "fraction_bars" => Definition.new(
      key: "fraction_bars",
      checker: ->(solution, state, _params) {
        state["shaded"].present? && state["shaded"].to_i == solution["shaded"].to_i
      },
      display: ->(state, params) { "#{state['shaded']}/#{params['segments']}" }
    )
  }.freeze

  module_function

  def keys
    REGISTRY.keys
  end

  def find(key)
    REGISTRY.fetch(key.to_s) { raise ArgumentError, "Unknown widget: #{key}" }
  end

  def correct?(key, solution:, state:, params: {})
    find(key).checker.call(solution || {}, state || {}, params || {})
  end

  def display(key, state:, params: {})
    find(key).display.call(state || {}, params || {})
  end
end
