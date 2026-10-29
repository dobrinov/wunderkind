module AdminStatsHelper
  # Sequential single-hue shading for the retention grid, darker for more.
  # Spelled out in full so Tailwind finds the classes; the text flips to
  # white where the fill gets dark enough to need it.
  COHORT_SHADES = [
    [ 80, "bg-primary-700 text-white" ],
    [ 60, "bg-primary-500 text-white" ],
    [ 40, "bg-primary-300 text-primary-950" ],
    [ 20, "bg-primary-100 text-primary-900" ],
    [ 0, "bg-primary-25 text-primary-900" ]
  ].freeze

  def cohort_shade(percent) = COHORT_SHADES.find { |floor, _| percent >= floor }.last

  # The line under a headline: how it moved against the period before.
  # `unit` is :percent for a count (relative change) or :points for a share
  # (percentage points). `better` says which way is good — :up, :down, or nil
  # where neither is (the correct share is aimed at a target, not maximised)
  # — and only then does the change carry a colour. The arrow is decoration;
  # the signed number says it to a screen reader.
  def stats_delta(compared, unit:, days:, better: :up)
    value = unit == :points ? compared.points : compared.change
    return tag.span(t("overseer.stats.no_comparison"), class: "text-ink-500") if value.nil?

    direction = value.positive? ? :up : (value.negative? ? :down : nil)
    tone = if direction.nil? || better.nil? then "text-ink-600"
    elsif direction == better then "text-green-700"
    else "text-red-700"
    end
    number = number_with_precision(value.abs, precision: unit == :points ? 1 : 0, strip_insignificant_zeros: true)
    sign = { up: "+", down: "−" }[direction]
    arrow = { up: "▲", down: "▼" }[direction]

    safe_join([
      tag.span(class: "font-black #{tone}") do
        safe_join([ (tag.span(arrow, "aria-hidden": true) if arrow), " ",
                    t("overseer.stats.delta.#{unit}", value: "#{sign}#{number}") ].compact)
      end,
      " ",
      t("overseer.stats.against", count: days)
    ])
  end
end
