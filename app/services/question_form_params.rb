# Turns the structured question form params (the admin authoring form) into
# Question attributes: the body parsed from its authoring text, per-type
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
      :body_source, :explanation, :answer_type, :status, :elo, :image,
      possible_answers_attributes: [ :id, :value, :correct, :_destroy ],
      topic_ids: []
    )

    attributes = permitted.except(:body_source, :image).to_h
    attributes[:possible_answers_attributes] = kept_options(attributes[:possible_answers_attributes], permitted[:answer_type]) if attributes.key?(:possible_answers_attributes)
    # The body is only rewritten when the form sent one, so an update that
    # carries no text (a status change from somewhere else) leaves it alone.
    attributes[:body] = parse_body(permitted[:body_source]) if permitted.key?(:body_source)
    attributes[:grading] = build_grading(params, permitted[:answer_type], question)
    attributes[:attachable] = QuestionImage.new(file: permitted[:image]) if permitted[:image].present?
    attributes
  end

  # The form always carries one empty option row to type into, and its
  # "correct" checkbox sends a hidden "0" — which is not blank, so
  # `reject_if: :all_blank` kept the row, the empty value failed validation, and
  # no exact-value or interactive question (96% of the bank) could be saved. A
  # new row with no value is nothing; on a question that is not multiple
  # choice, no new row is anything. Existing rows pass through untouched so a
  # removal (`_destroy`) still lands.
  def kept_options(options, answer_type)
    options.to_h.reject do |_index, option|
      next false if option["id"].present?

      option["value"].to_s.strip.empty? || (answer_type.present? && answer_type != "multiple_choice")
    end
  end

  # The admin form is the one place `$…$` is read as LaTeX; a bare "3/4" is a
  # fraction here as it is in a problem file and on /suggestions.
  def parse_body(text)
    RichContent.parse_authoring(text, latex: true)
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
        # A decimal comma is how a Bulgarian types 0,5; to_f read it as 0.
        "tolerance" => grading[:tolerance].presence&.tr(",", ".")&.to_f
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

  # The hint ladder as the editor sent it, or nil when the form carried no
  # hint fields at all (a save from somewhere that does not show them must
  # not wipe a ladder it never displayed).
  def hint_ladder(params)
    return unless params[:hint].respond_to?(:key?) && params[:hint].key?(:ladder)

    Array(params[:hint][:ladder]).map { |rung| rung.to_s.strip }.compact_blank
  end

  # The first rung that gives the answer away, by the rule tools/authoring's
  # check.rb applies to a problem file: a hint is read *instead of* giving up,
  # so it must not contain the answer. One-character answers are exempt, as
  # they are there — „3" is in half the hints ever written.
  def leaked_rung(question, ladder)
    answers =
      if question.multiple_choice?
        question.possible_answers.reject(&:marked_for_destruction?).select(&:correct?).map(&:value)
      elsif question.exact_value?
        [ question.grading["expected"] ]
      else
        []
      end
    answers = answers.map(&:to_s).select { |answer| answer.length > 1 }
    ladder.find { |rung| answers.any? { |answer| rung.include?(answer) } }
  end

  # Writes the ladder beside the question, with the meaning `reviewed_at` has
  # always had: a human looked at these words and approved them. Ticking
  # „прегледани" stamps it, unticking clears it, and saving an approved ladder
  # unchanged keeps the original stamp rather than pretending to a new review.
  # An emptied ladder removes the hint.
  def save_hint!(question, ladder, approved:)
    hint = question.hint
    return hint&.destroy! if ladder.empty?

    hint ||= question.build_hint
    unchanged = hint.persisted? && hint.ladder == ladder
    hint.ladder = ladder
    hint.reviewed_at = approved ? (unchanged && hint.reviewed_at) || Time.current : nil
    hint.save!
  end
end
