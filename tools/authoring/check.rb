#!/usr/bin/env ruby
# Checks the generated problem files before they are imported.
#
#   ruby tools/authoring/check.rb [db/seeds/ladders]
#
# What it verifies:
#   * the shape of every row (topic known, Elo in range, answer present)
#   * that answers are in a form ExactValue can parse — a non-numeric answer is
#     compared as a string, so "12 см" or a stray space marks a right answer wrong
#   * multiple choice: the answer is one of the options, options are distinct
#   * widgets: a known widget with the params its checker reads
#   * figures: the PNG the row points at exists
#   * explanations: present, multi-line, and long enough to be worth reading
#   * arithmetic: where the question is a bare expression ("Пресметни: 12 · 8 − 5.")
#     the expression is evaluated and compared with the stated answer
require "yaml"
require "set"

root = File.expand_path("../..", __dir__)
dir = ARGV[0] || File.join(root, "db/seeds/ladders")
topics = YAML.safe_load_file(File.join(root, "db/seeds/topics.yml")).fetch("topics").values.flatten.to_set
widgets = %w[number_line ordering fraction_bars multi_select blanks grid_fill grid_shade
             coordinate_plot categorize matcher angle_dial clock_hands].to_set

problems = Dir[File.join(dir, "*.yml")].sort.flat_map do |path|
  YAML.safe_load_file(path).fetch("problems").map { |row| row.merge("__file" => File.basename(path)) }
end

errors = Hash.new { |hash, key| hash[key] = [] }
seen = {}

# ExactValue's grammar: integer, decimal (either separator), fraction, mixed
# number, percent — anything else falls through to a string comparison.
NUMERIC = %r{\A[+-]?\d+([.,]\d+)?%?\z|\A[+-]?\d+/\d+\z|\A[+-]?\d+ \d+/\d+\z}

def evaluable(text)
  match = text.match(/\AПресметни:?\s+(.+?)\.\z/)
  return nil unless match

  expression = match[1]
  return nil unless expression.match?(/\A[\d\s+·:×()−\-²³]+\z/)

  # Floats, so ":" divides the way the question means it (27 : 5 = 5,4, not 5).
  expression.gsub("·", "*").gsub(":", "/").gsub("−", "-").gsub("²", "**2").gsub("³", "**3").
    gsub(/\d+/) { |digits| "#{digits}.0" }
end

problems.each do |row|
  text = row["text"].to_s
  where = "#{row['__file']}: #{text[0, 60]}"

  errors["empty text"] << where if text.strip.empty?
  errors["unknown topic #{row['topic']}"] << where unless topics.include?(row["topic"])
  # 2900 rather than 2400: the puzzle corpus deliberately reaches competition
  # ratings, where the dispatcher only sends them to the strongest students.
  errors["elo out of range"] << where unless (400..2900).cover?(row["elo"].to_i)
  errors["duplicate text"] << "#{where} (also in #{seen[text]})" if seen.key?(text)
  seen[text] = row["__file"]

  explanation = row["explanation"].to_s
  errors["missing explanation"] << where if explanation.strip.empty?
  errors["thin explanation"] << where if explanation.length < 120
  errors["explanation not stepped"] << where unless explanation.include?("\n1) ")
  errors["explanation has nil"] << where if explanation.include?("nil") || text.include?("nil")
  # A minus sign in Bulgarian typography is U+2212, not the ASCII hyphen — the
  # hyphen belongs in words like "по-голям". Interpolating a negative Integer
  # straight into a string is how the wrong one gets in.
  errors["ascii hyphen used as a minus"] << where if "#{text}\n#{explanation}".match?(/[\s(]-\d/)

  # A hint is read *instead of* giving up, so it must not contain the answer.
  # The explanation next to it may; that one is shown after a wrong answer.
  if row["hints"]
    hints = Array(row["hints"])
    joined = hints.join(" ")
    errors["hints: not a list of strings"] << where unless hints.all? { |rung| rung.is_a?(String) && rung.strip.length > 10 }
    errors["hints: too many rungs"] << where if hints.size > 4
    errors["hints: duplicate rungs"] << where if hints.uniq.size != hints.size
    errors["hints: a rung states the answer"] << where if row["answer"].to_s.length > 1 && joined.include?(row["answer"].to_s)
    if row.dig("widget", "solution", "values")
      # What a leak looks like in a blanks problem: a rung naming a box and its
      # value close together ("първа колонка — 1"). Digits alone prove nothing —
      # a hint that says which ladybugs a column *already* holds is exactly the
      # hint we want, and it is made of digits.
      values = row["widget"]["solution"]["values"]
      pairs = Array(row.dig("widget", "params", "fields")).filter_map do |field|
        value = values[field["id"].to_s]
        [ field["label"].to_s, value.to_s ] if value
      end
      # The value must stand as its own number: "извади възрастта на Дани от
      # сбора 11" is not a leak just because the answer is 1 and 11 contains it.
      leaked = hints.any? do |rung|
        pairs.any? do |label, value|
          label.length > 2 && rung.match?(/#{Regexp.escape(label)}.{0,14}(?<!\d)#{Regexp.escape(value)}(?!\d)/)
        end
      end
      errors["hints: a rung gives a blank away"] << where if leaked
    end
  end

  if row["widget"]
    widget = row["widget"]
    errors["unknown widget"] << where unless widgets.include?(widget["widget"])
    errors["widget without solution"] << where if widget["solution"].nil? || widget["solution"].empty?
    case widget["widget"]
    when "number_line"
      params = widget["params"] || {}
      value = widget.dig("solution", "value").to_f
      errors["number line: value outside range"] << where unless value.between?(params["min"].to_f, params["max"].to_f)
      steps = (value - params["min"].to_f) / params["step"].to_f
      errors["number line: value off the step grid"] << where if (steps - steps.round).abs > 0.01
      errors["number line: too many ticks"] << where if (params["max"].to_f - params["min"].to_f) / params["step"].to_f > 40
    when "ordering"
      items = widget.dig("params", "items") || []
      order = widget.dig("solution", "order") || []
      errors["ordering: items and order differ"] << where unless items.map { |item| item["id"] }.sort == order.sort
      errors["ordering: too few items"] << where if items.size < 3
      errors["ordering: duplicate labels"] << where if items.map { |item| item["label"] }.uniq.size != items.size
    when "fraction_bars"
      segments = widget.dig("params", "segments").to_i
      shaded = widget.dig("solution", "shaded").to_i
      errors["fraction bars: segments out of range"] << where unless (2..12).cover?(segments)
      errors["fraction bars: shaded out of range"] << where unless (0..segments).cover?(shaded)
    when "multi_select"
      options = widget.dig("params", "options") || []
      correct = widget.dig("solution", "correct") || []
      ids = options.map { |option| option["id"].to_s }
      errors["multi select: too few options"] << where if options.size < 4
      errors["multi select: duplicate labels"] << where if options.map { |option| option["label"] }.uniq.size != options.size
      errors["multi select: nothing correct"] << where if correct.empty?
      errors["multi select: everything correct"] << where if correct.size == options.size
      errors["multi select: unknown id in the solution"] << where unless (correct.map(&:to_s) - ids).empty?
    when "blanks"
      fields = widget.dig("params", "fields") || []
      values = widget.dig("solution", "values") || {}
      errors["blanks: no fields"] << where if fields.empty?
      errors["blanks: field without a value"] << where unless fields.all? { |field| values.key?(field["id"].to_s) }
      errors["blanks: value is not a number"] << where unless values.values.all? { |value| value.to_s.match?(NUMERIC) }
    when "grid_fill"
      rows = widget.dig("params", "rows") || []
      cells = widget.dig("solution", "cells") || {}
      blanks = rows.sum { |row| row.count(nil) }
      errors["grid fill: no blank cells"] << where if blanks.zero?
      errors["grid fill: blanks and answers disagree"] << where unless blanks == cells.size
      errors["grid fill: ragged rows"] << where unless rows.map(&:size).uniq.size == 1
      errors["grid fill: value is not a number"] << where unless cells.values.all? { |value| value.to_s.match?(NUMERIC) }
    when "grid_shade"
      params = widget["params"] || {}
      solution = widget["solution"] || {}
      size = params["rows"].to_i * params["cols"].to_i
      errors["grid shade: grid too big to click"] << where if size > 120 || size.zero?
      if solution["count"]
        errors["grid shade: count out of range"] << where unless (1...size).cover?(solution["count"].to_i)
      else
        cells = Array(solution["cells"])
        errors["grid shade: no cells to shade"] << where if cells.empty?
        errors["grid shade: cell outside the grid"] << where unless cells.all? do |cell|
          r, cc = cell.to_s.split(",").map(&:to_i)
          r.between?(0, params["rows"].to_i - 1) && cc.between?(0, params["cols"].to_i - 1)
        end
        errors["grid shade: cell already given"] << where if (cells & Array(params["given"])).any?
      end
    when "coordinate_plot"
      params = widget["params"] || {}
      points = Array(widget.dig("solution", "points"))
      errors["plot: no points to place"] << where if points.empty?
      errors["plot: count and solution disagree"] << where unless params["count"].to_i == points.size
      errors["plot: point outside the plane"] << where unless points.all? do |x, y|
        x.between?(params["min_x"], params["max_x"]) && y.between?(params["min_y"], params["max_y"])
      end
      errors["plot: point coincides with a given one"] << where if (points.map { |p| p.first(2) } & Array(params["fixed"]).map { |p| p.first(2) }).any?
    when "categorize"
      bins = widget.dig("params", "bins") || []
      items = widget.dig("params", "items") || []
      assignment = widget.dig("solution", "assignment") || {}
      errors["categorize: needs at least two bins"] << where if bins.size < 2
      errors["categorize: needs at least three items"] << where if items.size < 3
      errors["categorize: item without a bin"] << where unless items.all? { |item| assignment.key?(item["id"].to_s) }
      errors["categorize: unknown bin"] << where unless (assignment.values.map(&:to_s) - bins.map { |bin| bin["id"].to_s }).empty?
      errors["categorize: an empty bin"] << where unless bins.all? { |bin| assignment.value?(bin["id"].to_s) }
    when "matcher"
      left = widget.dig("params", "left") || []
      right = widget.dig("params", "right") || []
      pairs = widget.dig("solution", "pairs") || {}
      errors["matcher: needs at least two pairs"] << where if left.size < 2
      errors["matcher: sides differ in size"] << where unless left.size == right.size
      errors["matcher: left item without a pair"] << where unless left.all? { |item| pairs.key?(item["id"].to_s) }
      errors["matcher: duplicate labels"] << where if (left + right).map { |item| item["label"] }.uniq.size < left.size + right.size
    when "angle_dial"
      degrees = widget.dig("solution", "degrees").to_f
      max = widget.dig("params", "max").to_i
      step = widget.dig("params", "step").to_f
      errors["angle dial: angle outside the dial"] << where unless degrees.between?(0, max)
      errors["angle dial: angle off the step grid"] << where unless ((degrees / step) - (degrees / step).round).abs < 0.001 ||
                                                                    widget.dig("solution", "tolerance").to_f >= step
    when "clock_hands"
      hours = widget.dig("solution", "hours").to_i
      minutes = widget.dig("solution", "minutes").to_i
      step = widget.dig("params", "minute_step").to_i
      errors["clock: hour out of range"] << where unless (1..12).cover?(hours)
      errors["clock: minutes out of range"] << where unless (0..59).cover?(minutes)
      errors["clock: minutes off the step grid"] << where unless (minutes % step).zero?
    end
  elsif row["options"]
    options = row["options"]
    errors["options: answer not among them"] << where unless options.map(&:to_s).include?(row["answer"].to_s)
    errors["options: duplicates"] << where if options.map(&:to_s).uniq.size != options.size
    errors["options: too few"] << where if options.size < 3
  else
    answer = row["answer"].to_s
    errors["missing answer"] << where if answer.strip.empty?
    errors["answer not parseable as a number"] << "#{where} -> #{answer}" unless answer.match?(NUMERIC) || row["free_text"]
  end

  if row["image"]
    errors["missing image file"] << where unless File.exist?(File.join(root, row["image"]))
    errors["image without filename"] << where if row["image_filename"].to_s.empty?
  end

  expression = evaluable(text)
  if expression && row["answer"]
    begin
      value = eval(expression) # rubocop:disable Security/Eval — generated text, matched against a digits-only pattern
      stated = row["answer"].to_s.tr(",", ".").to_f
      errors["arithmetic mismatch"] << "#{where} -> #{value} vs #{row['answer']}" if (value - stated).abs > 0.001
    rescue StandardError => e
      errors["expression did not evaluate"] << "#{where} (#{e.class})"
    end
  end
end

puts "Checked #{problems.size} problems from #{Dir[File.join(dir, '*.yml')].size} files."
if errors.empty?
  puts "No problems found."
else
  errors.sort_by { |_, list| -list.size }.each do |kind, list|
    puts "\n#{kind}: #{list.size}"
    list.first(5).each { |line| puts "  #{line}" }
  end
  exit 1
end
