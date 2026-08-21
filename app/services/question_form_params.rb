# Turns the structured question form params (shared by the admin and teacher
# authoring forms) into Question attributes: parsed rich body, per-type
# grading JSON, and an optional image attachable.
module QuestionFormParams
  module_function

  # The widgets the authoring form can build by hand. The rest of the registry
  # (grids, plots, matchers, dials) is authored in tools/authoring, where the
  # parameters are generated together with the problem; a form for them would be
  # a worse editor than the family that produced them.
  EDITABLE_WIDGETS = %w[number_line ordering fraction_bars].freeze

  def build(params, question = nil)
    permitted = params.require(:question).permit(
      :body_json, :explanation, :answer_type, :status, :elo, :image,
      possible_answers_attributes: [ :id, :value, :correct, :_destroy ],
      topic_ids: []
    )

    attributes = permitted.except(:body_json, :image).to_h
    attributes[:body] = parse_body(permitted[:body_json])
    attributes[:grading] = build_grading(params, permitted[:answer_type], question)
    attributes[:attachable] = QuestionImage.new(file: permitted[:image]) if permitted[:image].present?
    attributes
  end

  def parse_body(body_json)
    JSON.parse(body_json.to_s)
  rescue JSON::ParserError
    nil
  end

  def build_grading(params, answer_type, question = nil)
    grading = params.require(:question).permit(
      :expected, :tolerance, :widget, :rubric,
      :nl_min, :nl_max, :nl_step, :nl_solution, :nl_tolerance,
      :ordering_items, :fb_segments, :fb_shaded
    )

    case answer_type
    when "exact_value"
      {
        "expected" => grading[:expected].to_s.strip,
        "tolerance" => grading[:tolerance].presence&.to_f
      }.compact
    when "interactive"
      widget_grading(grading, question)
    when "free_text"
      { "rubric" => grading[:rubric].to_s.strip }
    else
      {}
    end
  end

  def widget_grading(grading, question = nil)
    # A question built by the authoring toolchain keeps its grading: the form
    # has no editor for that widget, and rebuilding it from blank fields would
    # throw the solution away.
    return question.grading if question&.interactive? && !EDITABLE_WIDGETS.include?(grading[:widget].to_s)

    case grading[:widget]
    when "number_line"
      {
        "widget" => "number_line",
        "params" => {
          "min" => grading[:nl_min].to_f,
          "max" => grading[:nl_max].to_f,
          "step" => grading[:nl_step].presence&.to_f || 1
        },
        "solution" => {
          "value" => grading[:nl_solution].to_f,
          "tolerance" => grading[:nl_tolerance].presence&.to_f || 0
        }
      }
    when "ordering"
      items = grading[:ordering_items].to_s.split(/\r?\n/).map(&:strip).reject(&:blank?)
      {
        "widget" => "ordering",
        "params" => { "items" => items.each_with_index.map { |label, i| { "id" => "i#{i + 1}", "label" => label } } },
        "solution" => { "order" => items.each_index.map { |i| "i#{i + 1}" } }
      }
    when "fraction_bars"
      {
        "widget" => "fraction_bars",
        "params" => { "segments" => grading[:fb_segments].to_i },
        "solution" => { "shaded" => grading[:fb_shaded].to_i }
      }
    else
      {}
    end
  end
end
