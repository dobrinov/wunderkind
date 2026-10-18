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
#   * puzzles whose answer a search can confirm: the problem is solved again
#     from its text and every solution counted. A widget grades against one
#     stored answer, so a problem with two right answers marks one of them
#     wrong — and three families shipped exactly that before this existed.
require "yaml"
require "set"
$LOAD_PATH.unshift File.join(__dir__, "lib")
require "tiling"
require "uniqueness"

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

# Re-solves the puzzle shapes that have more than one plausible answer, from
# the text alone, and returns what is wrong with the stored solution.
def solve_again(text, widget)
  values = widget&.dig("solution", "values") || {}
  found = []

  if (match = text.match(/AB и обърнатото му BA дават сбор (\d+)/))
    numbers = (1..9).to_a.permutation(2).select { |x, y| 11 * (x + y) == match[1].to_i }
    if values.key?("count")
      found << "puzzle: wrong count of AB + BA numbers" unless values["count"].to_i == numbers.size
    else
      found << "puzzle: AB + BA asks for one pair but has several" if numbers.size > 2
    end
  end

  if (match = text.match(/с (\d+) по-голямо от числото, записано с неговите цифри в обратен ред/)) && text.include?("възможно най-малки")
    pairs = (1..9).to_a.product((1..9).to_a).select { |tens, ones| 9 * (tens - ones) == match[1].to_i }
    tens, ones = pairs.min_by(&:last)
    found << "puzzle: digit difference key is not the smallest units digit" unless values["tens"].to_i == tens && values["ones"].to_i == ones
  end

  if (match = text.match(/\AКои от дъските (.+) могат да се покрият изцяло с плочки домино/))
    options = widget.dig("params", "options")
    correct = widget.dig("solution", "correct").map(&:to_s)
    options.each do |option|
      board = Tiling.parse(option["label"])
      next found << "puzzle: domino board does not say which corners are gone" if board.nil?

      rows, cols, kind = board
      expected = Tiling.tileable?(rows, cols, Tiling.corners(rows, cols, kind))
      found << "puzzle: domino board marked wrongly" unless expected == correct.include?(option["id"].to_s)
    end
  end

  if text.include?("(най-близката отметка)") && (match = text.match(/\AПресметни (.+?) и постави точката/))
    exact = eval(match[1].gsub("·", "*").gsub("−", "-")) # rubocop:disable Security/Eval — generated digits and operators
    step = widget.dig("params", "step").to_f
    remainder = exact % step
    found << "puzzle: value is exactly between two ticks" if (remainder * 2 - step).abs < 1e-9
    nearest = remainder * 2 < step ? exact - remainder : exact - remainder + step
    found << "puzzle: number line value is not the nearest tick" unless (widget.dig("solution", "value").to_f - nearest).abs < 1e-9
  end

  if (match = text.match(/\AВ събирането (\S+) \+ (\S+) = (\d+) са скрити две цифри/))
    left, right, sum = match.captures
    pairs = (0..9).to_a.product((0..9).to_a).select do |a, b|
      x, y = left.sub("☐", a.to_s), right.sub("☐", b.to_s)
      !x.start_with?("0") && !y.start_with?("0") && x.to_i + y.to_i == sum.to_i
    end
    found << "puzzle: missing digits admit #{pairs.size} answers" unless pairs.size == 1
    found << "puzzle: missing digits stored wrong" unless pairs.size != 1 || pairs.first == [ values["a"].to_i, values["b"].to_i ]
  end

  options = widget&.dig("params", "options") || []
  correct = (widget&.dig("solution", "correct") || []).map(&:to_s)
  marked = ->(option) { correct.include?(option["id"].to_s) }

  if (match = text.match(/\AИзбери всички числа от списъка .+, които се делят на (\d+)\./))
    options.each { |option| found << "pick: divisibility marked wrongly" unless (option["label"].to_i % match[1].to_i).zero? == marked.(option) }
  end

  if (match = text.match(/\AИзбери всички дроби, равни на (\d+)\/(\d+)/))
    target = Rational(match[1].to_i, match[2].to_i)
    options.each { |option| found << "pick: fraction marked wrongly" unless (Rational(*option["label"].split("/").map(&:to_i)) == target) == marked.(option) }
    found << "pick: no equal fraction besides the target itself" if options.count(&marked) < 2
  end

  if (match = text.match(/Ученик има (\d+) тениски и (\d+) панталона/))
    outfits = match[1].to_i * match[2].to_i
    options.each do |option|
      next if marked.(option) || option["label"].include?("станат")

      found << "pick: a wrong outfit statement gives the true count" if option["label"][/(\d+) различни облекла/, 1].to_i == outfits
    end
  end

  # Sorting into two bins with a boundary between them: an item exactly on the
  # boundary belongs in neither.
  labels = (widget&.dig("params", "items") || []).map { |item| item["label"].to_s }
  found << "sort: a right angle is neither acute nor obtuse" if text.include?("на остри и тъпи") && labels.include?("90°")
  found << "sort: 50% is exactly half" if text.include?("повече или по-малко от половината") && labels.any? { |label| label.start_with?("50% ") }
  found << "sort: 0 is neither negative nor positive" if (widget&.dig("params", "bins") || []).any? { |bin| bin["label"] == "положителни" } && labels.include?("0")

  if widget&.dig("widget") == "grid_fill"
    grid = widget.dig("params", "rows").map(&:dup)
    filled = widget.dig("solution", "cells").to_h { |cell, value| [ cell.split(",").map(&:to_i), value.to_i ] }
    known = grid.each_with_index.flat_map { |row, r| row.each_index.map { |c| [ [ r, c ], row[c].nil? ? filled[[ r, c ]] : row[c] ] } }.to_h
    unknowns = filled.keys

    if text.include?("Попълни магическия квадрат") && (constant = text[/дават сбор (\d+)/, 1])
      found << "puzzle: magic square has more than one completion" unless Uniqueness.linear?(unknowns, Uniqueness.magic_square(constant.to_i), known)
    elsif text.include?("В сборната пирамида")
      found << "puzzle: pyramid has more than one completion" unless Uniqueness.linear?(unknowns, Uniqueness.pyramid, known)
    elsif (match = text.match(/\AПопълни квадрата (\d+) на \d+ така, че всяко от числата от 1 до/))
      found << "puzzle: Latin square has more than one completion" unless Uniqueness.latin_completions(grid, (1..match[1].to_i).to_a) == 1
    elsif (match = text.match(/числата във всеки ред са ([\d, ]+?) в някакъв ред/))
      found << "puzzle: table has more than one completion" unless Uniqueness.latin_completions(grid, match[1].split(", ").map(&:to_i)) == 1
    end
  end

  if (match = text.match(/\AСред (\d+) монети има една по-лека/))
    weighings = 0
    weighings += 1 while 3**weighings < match[1].to_i
    found << "puzzle: weighings count is not the smallest" unless values["w"].to_i == weighings && values["max"].to_i == 3**weighings
  end

  # puzzle.cross_square: a five-by-five square of three row and three column
  # additions. The cells between the signs are "" (outside the puzzle) and never
  # nil (a blank to fill in); only the nil cells are stored; the filled square
  # satisfies all six equations; and the blanks admit one completion only.
  # (logic.maze_order, logic.maze_walk and logic.puzzle_hole carry their layout
  # in the figure alone, so there is nothing in the text to solve again.)
  if text.start_with?("В квадрата 5 на 5 всеки ред и всяка колона от числа е равенство със събиране") &&
     widget&.dig("widget") == "grid_fill"
    grid = widget.dig("params", "rows")
    stored = widget.dig("solution", "cells") || {}
    numbers = [ 0, 2, 4 ].product([ 0, 2, 4 ])
    spacers = [ 1, 3 ].product([ 1, 3 ])
    blanks = numbers.select { |r, c| grid[r][c].nil? }
    found << "puzzle: cross square is not five by five" unless grid.size == 5 && grid.all? { |line| line.size == 5 }
    found << "puzzle: cross square spacer is not \"\"" unless spacers.all? { |r, c| grid[r][c] == "" }
    found << "puzzle: cross square sign cell is blank" unless grid.each_with_index.all? { |line, r| line.each_index.all? { |c| !grid[r][c].nil? || numbers.include?([ r, c ]) } }
    found << "puzzle: cross square solution does not cover exactly the blanks" unless stored.keys.sort == blanks.map { |r, c| "#{r},#{c}" }.sort
    value = ->(r, c) { (grid[r][c].nil? ? stored["#{r},#{c}"] : grid[r][c]).to_i }
    lines = [ 0, 2, 4 ].flat_map { |i| [ [ [ i, 0 ], [ i, 2 ], [ i, 4 ] ], [ [ 0, i ], [ 2, i ], [ 4, i ] ] ] }
    found << "puzzle: cross square equation does not hold" unless lines.all? { |a, b, sum| value.(*a) + value.(*b) == value.(*sum) }
    equations = lines.map { |a, b, sum| [ { a => 1, b => 1, sum => -1 }, 0 ] }
    known = (numbers - blanks).to_h { |cell| [ cell, value.(*cell) ] }
    found << "puzzle: cross square has more than one completion" unless Uniqueness.linear?(blanks, equations, known)
  end

  found.uniq
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
  # An explanation that solves 2/4 when the problem says 1/2 was written for
  # different numbers; one that never mentions the problem's fractions at all
  # is not about this problem.
  fractions = text.scan(%r{(?<![\d,/])\d+/\d+(?![\d/])}).uniq
  errors["explanation skips a fraction from the problem"] << where unless fractions.all? { |fraction| explanation.include?(fraction) }
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
      if (sides = solution["rectangle"])
        fits = sides.map(&:to_i).then { |a, b| (a <= params["rows"].to_i && b <= params["cols"].to_i) || (b <= params["rows"].to_i && a <= params["cols"].to_i) }
        errors["grid shade: rectangle does not fit the grid"] << where unless sides.size == 2 && fits
        errors["grid shade: text does not name the rectangle"] << where unless text.include?("#{sides[0]} на #{sides[1]}") || text.include?("#{sides[1]} и #{sides[0]}")
      elsif solution["count"]
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
      errors["categorize: duplicate labels"] << where if items.map { |item| item["label"] }.uniq.size != items.size
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

  solve_again(text, row["widget"]).each { |kind| errors[kind] << where }

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
