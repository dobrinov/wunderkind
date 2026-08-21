# Логически задачи с извеждане: "кой колко реши" и латински квадрат с калинки.
#
# Two shapes of deduction puzzle live here. The first is the one competition
# papers use for their easy logic slot: a fixed tally is shared out among named
# people (three solved 3 problems, two solved 2), a couple of clues relate them,
# and the student has to work out who is who. The second is a grid — a Latin
# square whose symbols are pictures, so it can be set 700 points lower down the
# ladder than the numeral version.
#
# Every puzzle in the file is generated *and then verified*: the builder
# enumerates every arrangement consistent with the clues and keeps the puzzle
# only if the thing it asks about is the same in all of them. A deduction puzzle
# with two answers is not a puzzle.

DEDUCTION_LADDER = [ 1050, 1200, 1350, 1500, 1650, 1800, 1950 ].freeze

# What the people are counting. Only the noun changes; the reasoning does not.
#
# `one` is the form a *single* one of them takes: Bulgarian says "1 задача" but
# "2 задачи", and these puzzles talk about people who solved exactly one. Every
# place a number meets the noun goes through `deduction_noun`.
DEDUCTION_CONTEXTS = [
  { noun: "задачи", one: "задача", verb: "реши", plural_verb: "решиха", activity: "решаваха задачи" },
  { noun: "точки", one: "точка", verb: "събра", plural_verb: "събраха", activity: "събираха точки" },
  { noun: "книги", one: "книга", verb: "прочете", plural_verb: "прочетоха", activity: "четоха книги" },
  { noun: "мача", one: "мач", verb: "изигра", plural_verb: "изиграха", activity: "играха мачове" },
  { noun: "стикера", one: "стикер", verb: "събра", plural_verb: "събраха", activity: "събираха стикери" }
].freeze

# "1 задача", "2 задачи".
def deduction_noun(context, count) = count_noun(count, context[:one], context[:noun])

Clue = Struct.new(:text, :test, :kind, :who, keyword_init: true)

# "Трима от тях", not "3 от тях" — Bulgarian counts people with their own words.
PEOPLE_COUNT = { 1 => "един", 2 => "двама", 3 => "трима", 4 => "четирима",
                 5 => "петима", 6 => "шестима", 7 => "седмина" }.freeze

def people_count(number) = PEOPLE_COUNT.fetch(number, number.to_s)

def name_list(names) = names.size < 2 ? names.first.to_s : "#{names[0..-2].join(', ')} и #{names[-1]}"

def clue_sentence(clues)
  texts = clues.map(&:text)
  texts.size < 2 ? texts.first.to_s : "#{texts[0..-2].join(', ')}, а #{texts[-1]}"
end

module Deduction
  module_function

  # Every way of handing out the tally: choose which people get the low value.
  def assignments(people, low_count, high, low)
    people.combination(low_count).map do |low_people|
      people.to_h { |person| [ person, low_people.include?(person) ? low : high ] }
    end
  end

  def clue_for(kind, target, context, high, low, pair)
    first, second = pair
    case kind
    when :greater
      Clue.new(kind: kind, who: pair,
               text: "#{first} #{context[:verb]} повече #{context[:noun]} от #{second}",
               test: ->(a) { a[first] > a[second] })
    when :equal
      Clue.new(kind: kind, who: pair,
               text: "#{first} и #{second} #{context[:plural_verb]} еднакъв брой #{context[:noun]}",
               test: ->(a) { a[first] == a[second] })
    when :different
      Clue.new(kind: kind, who: pair,
               text: "#{first} и #{second} #{context[:plural_verb]} различен брой #{context[:noun]}",
               test: ->(a) { a[first] != a[second] })
    when :direct
      value = target[first]
      Clue.new(kind: kind, who: [ first ],
               text: "#{first} #{context[:verb]} #{deduction_noun(context, value)}",
               test: ->(a) { a[first] == value })
    when :negative
      missing = target[first] == high ? low : high
      Clue.new(kind: kind, who: [ first ],
               text: "#{first} не #{context[:verb]} #{deduction_noun(context, missing)}",
               test: ->(a) { a[first] != missing })
    end
  end

  # Clues that are true of the intended answer, on people drawn without repeats
  # where the clue needs two of them.
  def build_clues(context, target, high, low, kinds, chooser)
    people = target.keys
    seen = []
    kinds.filter_map do |kind|
      pool = people
      case kind
      when :greater
        high_people = pool.select { |person| target[person] == high }
        low_people = pool.select { |person| target[person] == low }
        next if high_people.empty? || low_people.empty?

        pair = [ chooser.call(high_people), chooser.call(low_people) ]
      when :equal
        same = pool.group_by { |person| target[person] }.values.select { |group| group.size >= 2 }
        next if same.empty?

        pair = chooser.call(same).first(2)
      when :different
        next if pool.map { |person| target[person] }.uniq.size < 2

        pair = [ chooser.call(pool.select { |person| target[person] == high }),
                 chooser.call(pool.select { |person| target[person] == low }) ]
        pair = pair.reverse if chooser.call([ true, false ])
      else
        next if pool.empty?

        pair = [ chooser.call(pool) ]
      end

      # The same fact twice is not a second clue.
      next if seen.include?([ kind, pair.sort ])

      seen << [ kind, pair.sort ]
      clue_for(kind, target, context, high, low, pair)
    end
  end

  # The written derivation, produced by actually deducing rather than by
  # describing. Each clue is applied whenever it can pin somebody down, and the
  # loop runs until nothing new follows; the count of unfilled places closes the
  # argument. If the deduction cannot finish, the puzzle is thrown away — an
  # explanation that hand-waves is worse than one problem fewer.
  def narrate(clues, target, high, low, low_count, context)
    people = target.keys
    high_count = people.size - low_count
    known = {}
    steps = []
    said = []
    left = ->(value) { (value == low ? low_count : high_count) - known.count { |_, held| held == value } }
    pin = lambda do |person, value|
      return false if known[person]

      known[person] = value
      true
    end

    (clues.size + 1).times do
      changed = false

      clues.each do |clue|
        case clue.kind
        when :direct, :negative
          person = clue.who.first
          next unless pin.call(person, target[person])

          changed = true
          steps << (clue.kind == :direct ?
            "„#{clue.text}“ дава направо: #{person} — #{deduction_noun(context, target[person])}." :
            "Стойностите са само две, затова „#{clue.text}“ значи #{person} — #{deduction_noun(context, target[person])}.")
        when :greater
          first, second = clue.who
          pinned = [ pin.call(first, high), pin.call(second, low) ].any?
          next unless pinned

          changed = true
          steps << "Стойностите са само две, затова „#{clue.text}“ значи #{first} — #{high}, а #{second} — #{low}."
        when :equal, :different
          first, second = clue.who
          same = clue.kind == :equal
          if known[first] && !known[second]
            value = same ? known[first] : (known[first] == high ? low : high)
            pin.call(second, value)
            changed = true
            steps << "#{first} вече е с #{known[first]}, затова „#{clue.text}“ дава #{second} — #{value}."
          elsif known[second] && !known[first]
            value = same ? known[second] : (known[second] == high ? low : high)
            pin.call(first, value)
            changed = true
            steps << "#{second} вече е с #{known[second]}, затова „#{clue.text}“ дава #{first} — #{value}."
          elsif same && !known[first] && !known[second] && (left.call(low) < 2 || left.call(high) < 2)
            value = left.call(low) < 2 ? high : low
            other = value == high ? low : high
            steps << "Местата за #{deduction_noun(context, other)} са заети до едно, а „#{clue.text}“ иска две еднакви — " \
                     "значи и двамата са с #{value}."
            pin.call(first, value)
            pin.call(second, value)
            changed = true
          elsif !said.include?(clue)
            said << clue
            steps << (same ?
              "„#{clue.text}“ ги обвързва: или и двамата са с #{high}, или и двамата с #{low}." :
              "„#{clue.text}“ значи, че единият е с #{high}, а другият с #{low}.")
          end
        end
      end

      break unless changed
    end

    rest = people - known.keys
    unless rest.empty?
      # The last people follow from counting only if one of the two values has
      # run out; otherwise this puzzle needs an argument this narrator cannot
      # write, and it is dropped.
      return nil unless left.call(low).zero? || left.call(high).zero? || rest.size == left.call(low) || rest.size == left.call(high)

      value = left.call(low).zero? ? high : (left.call(high).zero? ? low : (rest.size == left.call(low) ? low : high))
      rest.each { |person| known[person] = value }
      steps << "Местата за #{deduction_noun(context, value == high ? low : high)} вече са запълнени, затова " \
               "#{name_list(rest)} #{rest.size == 1 ? 'е' : 'са'} с #{value}."
    end

    # A derivation that disagrees with the intended answer is a bug, not a hint.
    return nil unless known == target

    steps
  end
end

# One generator, three question formats. The block returns the puzzle or nil.
def deduction_puzzle(context_pick, spec, chooser)
  context = context_pick
  people = spec[:people]
  high = spec[:high]
  low = spec[:low]
  low_count = spec[:low_count]

  target_low = chooser.call(people.combination(low_count).to_a)
  target = people.to_h { |person| [ person, target_low.include?(person) ? low : high ] }

  clues = Deduction.build_clues(context, target, high, low, spec[:kinds], chooser)
  return nil if clues.size < spec[:kinds].size

  fits = Deduction.assignments(people, low_count, high, low).select { |a| clues.all? { |clue| clue.test.call(a) } }
  return nil unless fits.size == 1

  steps = Deduction.narrate(clues, target, high, low, low_count, context)
  return nil if steps.nil?

  { context: context, people: people, high: high, low: low, low_count: low_count,
    target: target, clues: clues, steps: steps }
end

def deduction_spec(c)
  spec = c.by_level([
    { size: 4, low_count: 2, kinds: [ :direct, :greater ] },
    { size: 4, low_count: 1, kinds: [ :greater, :equal ] },
    { size: 5, low_count: 2, kinds: [ :greater, :equal ] },
    { size: 5, low_count: 2, kinds: [ :negative, :equal ] },
    { size: 5, low_count: 3, kinds: [ :greater, :equal, :equal ] },
    { size: 6, low_count: 2, kinds: [ :greater, :equal, :different ] },
    { size: 6, low_count: 3, kinds: [ :negative, :equal, :different, :equal ] }
  ])
  low = c.int(c.by_level([ 1..3, 1..3, 2..4, 2..5, 3..6, 3..8, 4..12 ]))
  gap = c.int(c.by_level([ 1..1, 1..2, 1..2, 1..3, 1..3, 1..4, 1..5 ]))

  spec.merge(people: c.sample(Props::NAMES, spec[:size]), low: low, high: low + gap)
end

def deduction_intro(puzzle)
  context = puzzle[:context]
  high_count = puzzle[:people].size - puzzle[:low_count]
  "#{name_list(puzzle[:people])} #{context[:activity]}. " \
    "#{people_count(high_count).capitalize} от тях #{context[:plural_verb]} по #{deduction_noun(context, puzzle[:high])}, " \
    "а #{people_count(puzzle[:low_count])} — по #{deduction_noun(context, puzzle[:low])}. " \
    "#{clue_sentence(puzzle[:clues])}."
end

# ---------------------------------------------------------------------------

# The hint ladder the three tally families share: the counting argument, then
# where to start, then the trap. No rung names anybody's number — in all three
# shapes that *is* the answer.
def deduction_hints(puzzle)
  [
    "Броят е известен още от условието: #{puzzle[:low_count]} от тях са с #{puzzle[:low]}, значи останалите " \
    "#{puzzle[:people].size - puzzle[:low_count]} са с #{puzzle[:high]}.",
    "Тръгни от подсказка, която сравнява двама: тя не казва точен брой, но изключва една от двете възможности за тях.",
    "Разпределението трябва да изпълнява всички подсказки едновременно — една изпълнена подсказка не стига."
  ]
end

Authoring.family "deduce.minority_group", topic: "Логически задачи", area: "interactive_logic", variants: 9,
                 rungs: DEDUCTION_LADDER do |c|
  puzzle = deduction_puzzle(c.pick(DEDUCTION_CONTEXTS), deduction_spec(c), ->(list) { c.pick(list) })
  raise Authoring::Duplicate if puzzle.nil?

  low_people = puzzle[:target].select { |_, value| value == puzzle[:low] }.keys
  options = puzzle[:people].map { |person| [ person, low_people.include?(person) ] }

  c.q(
    text: "#{deduction_intro(puzzle)} Кои от тях #{puzzle[:context][:plural_verb]} точно по " \
          "#{deduction_noun(puzzle[:context], puzzle[:low])}? Избери всички.",
    widget: WidgetKit.multi_select(options),
    hints: deduction_hints(puzzle),
    explanation: Explain.build(
      idea: "Броят на всяка стойност е известен предварително — затова всяка подсказка не само казва нещо за двама души, " \
            "а и заема места, които на останалите вече не достигат.",
      steps: puzzle[:steps],
      answer: low_people.join(" и "),
      check: "#{puzzle[:target].map { |person, value| "#{person} — #{value}" }.join(', ')}: " \
             "#{puzzle[:people].size - puzzle[:low_count]} души с #{puzzle[:high]} и #{puzzle[:low_count]} с #{puzzle[:low]}, " \
             "точно както иска условието.",
      watch: "Еднакъв брой не значи по-малкият брой — когато местата за #{puzzle[:low]} са заети, " \
             "равните двама са принудени да са с #{puzzle[:high]}."
    )
  )
end

Authoring.family "deduce.assign_all", topic: "Логически задачи", area: "interactive_logic", variants: 9,
                 rungs: DEDUCTION_LADDER do |c|
  puzzle = deduction_puzzle(c.pick(DEDUCTION_CONTEXTS), deduction_spec(c), ->(list) { c.pick(list) })
  raise Authoring::Duplicate if puzzle.nil?

  items = puzzle[:people].each_with_index.map do |person, index|
    [ "p#{index}", person, puzzle[:target][person] == puzzle[:high] ? "hi" : "lo" ]
  end

  c.q(
    text: "#{deduction_intro(puzzle)} Разпредели всеки според броя #{puzzle[:context][:noun]}.",
    widget: WidgetKit.categorize(
      bins: [ [ "hi", "по #{puzzle[:high]}" ], [ "lo", "по #{puzzle[:low]}" ] ],
      items: items
    ),
    hints: deduction_hints(puzzle),
    explanation: Explain.build(
      idea: "Тръгваме от подсказката, която определя някого със сигурност, и всеки път броим колко места остават.",
      steps: puzzle[:steps],
      answer: puzzle[:target].map { |person, value| "#{person} — #{value}" }.join(", "),
      check: "Броят по групи излиза: #{puzzle[:people].size - puzzle[:low_count]} с #{puzzle[:high]} и " \
             "#{puzzle[:low_count]} с #{puzzle[:low]}.",
      watch: "Всяко разпределение трябва да изпълнява *всички* подсказки едновременно — една вярна не стига."
    )
  )
end

Authoring.family "deduce.two_people", topic: "Логически задачи", area: "interactive_logic", variants: 9,
                 rungs: DEDUCTION_LADDER do |c|
  puzzle = deduction_puzzle(c.pick(DEDUCTION_CONTEXTS), deduction_spec(c), ->(list) { c.pick(list) })
  raise Authoring::Duplicate if puzzle.nil?

  asked = c.sample(puzzle[:people], 2)
  raise Authoring::Duplicate if asked.map { |person| puzzle[:target][person] }.uniq.size < 2

  c.q(
    text: "#{deduction_intro(puzzle)} Попълни колко #{puzzle[:context][:noun]} " \
          "#{puzzle[:context][:verb]} #{asked[0]} и колко #{asked[1]}.",
    widget: WidgetKit.blanks(asked.each_with_index.map { |person, index| [ "p#{index}", person, puzzle[:target][person] ] }),
    hints: deduction_hints(puzzle),
    explanation: Explain.build(
      idea: "Първо се определят хората, които подсказките назовават пряко, после броенето довършва останалите.",
      steps: puzzle[:steps],
      answer: asked.map { |person| "#{person} — #{puzzle[:target][person]}" }.join(", "),
      check: "Пълното разпределение е #{puzzle[:target].map { |person, value| "#{person} — #{value}" }.join(', ')}.",
      watch: "Двамата в отговора са с различен брой — ако и двете кутийки излязат еднакви, някоя подсказка е пропусната."
    )
  )
end

# --------------------------------------- Латински квадрат с калинки ---
#
# The picture version of the Latin square, the way competition sheets set it for
# the youngest children: the symbols are ladybugs with 1..n spots, so solving it
# needs counting rather than reading digits. `puzzle.latin_square` (in
# interactive_puzzles.rb) is the numeral version for older students and starts at
# 1550; this ladder starts 700 points lower and asks about one line of the grid
# rather than the whole of it.
#
# Two properties are enumerated rather than hoped for:
#
#   * every cell the question asks about holds the same ladybug in *every* Latin
#     square consistent with the clues — otherwise the question has more than
#     one answer;
#   * the answer is reachable by row/column elimination alone, and the builder
#     keeps the chain of deductions it used as the explanation. A problem whose
#     derivation the narrator cannot finish is dropped rather than explained
#     with "по изключване" as if that were a step.

LADYBUG_RUNGS = [ 850, 970, 1090, 1210, 1330, 1450, 1570 ].freeze

# Bulgarian counts rows as masculine ("трети ред") and columns as feminine
# ("трета колонка"), and the question needs the definite forms too.
LADYBUG_ROWS = %w[първи втори трети четвърти].freeze
LADYBUG_ROWS_DEF = %w[първия втория третия четвъртия].freeze
LADYBUG_COLS = %w[първа втора трета четвърта].freeze
LADYBUG_COLS_DEF = %w[първата втората третата четвъртата].freeze

def ladybug_spots(count) = "#{count} #{count == 1 ? 'точка' : 'точки'}"

def ladybug_cell_name(row, col) = "#{LADYBUG_ROWS[row]} ред, #{LADYBUG_COLS[col]} колонка"

# "във втория ред", but "в третия ред": the preposition doubles before a word
# that starts with в or ф.
def ladybug_in(phrase) = "#{phrase.start_with?('в', 'ф') ? 'във' : 'в'} #{phrase}"

# Every Latin square of a size, built row by row: 12 of them for 3, 576 for 4.
def ladybug_squares(size, rows = [])
  return [ rows ] if rows.size == size

  (1..size).to_a.permutation.
    select { |row| rows.none? { |previous| previous.zip(row).any? { |a, b| a == b } } }.
    flat_map { |row| ladybug_squares(size, rows + [ row ]) }
end

LADYBUG_CACHE = {}
def ladybug_all(size) = (LADYBUG_CACHE[size] ||= ladybug_squares(size))

# Rows that are all rotations of the first are guessable from one row, so they
# are rejected — for size 3 that is every square there is, which is why the
# check only applies from 4 up.
def ladybug_cyclic?(square)
  return false if square.size < 4

  rotations = (0...square.size).map { |shift| square.first.rotate(shift) }
  square.all? { |row| rotations.include?(row) }
end

# One elimination step: a cell whose row and column between them rule out
# everything but a single ladybug. That is the whole method — no candidate
# bookkeeping, nothing a seven-year-old cannot do with a finger on the page.
#
# Returns the cell, the value, and the *reasoning without the conclusion* — "in
# this row there is already 2 and 3, in this column a 4". The explanation adds
# "so a 1 is left"; a hint stops at the comma and lets the student finish it.
def ladybug_step(known, size, priority)
  values = (1..size).to_a
  order = priority + ((0...size).to_a.product((0...size).to_a) - priority)

  order.each do |row, col|
    next if known.key?([ row, col ])

    in_row = values.select { |value| (0...size).any? { |x| known[[ row, x ]] == value } }
    in_col = values.select { |value| (0...size).any? { |y| known[[ y, col ]] == value } }
    left = values - in_row - in_col
    next unless left.size == 1

    reasons = []
    reasons << "в реда вече има #{in_row.join(', ')}" unless in_row.empty?
    reasons << "в колонката — #{in_col.join(', ')}" unless in_col.empty?
    return [ [ row, col ], left.first, "#{ladybug_cell_name(row, col)}: #{reasons.join(', а ')}" ]
  end

  nil
end

# The chain of eliminations up to the point where every asked cell is known, or
# nil if elimination alone does not get there.
def ladybug_chain(clues, size, asked)
  known = clues.dup
  chain = []

  until asked.all? { |cell| known.key?(cell) }
    cell, value, reasoning = ladybug_step(known, size, asked)
    return nil if cell.nil?

    known[cell] = value
    chain << [ cell, value, reasoning ]
  end

  chain
end

Authoring.family "puzzle.ladybug_square", topic: "Логически задачи", area: "interactive_logic", variants: 8,
                 rungs: LADYBUG_RUNGS do |c|
  size = c.by_level([ 3, 3, 4, 4, 4, 4, 4 ])
  clue_count = c.by_level([ 5, 4, 7, 6, 6, 6, 6 ])
  # Where the question points. The bottom row is the printed original; a row in
  # the middle and then a column come later, when reading the grid is no longer
  # the hard part.
  target = c.by_level([ :bottom, :bottom, :bottom, :bottom, :middle_row, :column, :column ])
  asked_band = c.by_level([ 2..3, 2..3, 2..3, 2..3, 2..3, 2..4, 2..4 ])
  # The real ladder. The grid stops growing at 4x4, so difficulty is the length
  # of the reasoning: how many cells *outside* the asked line have to be worked
  # out before the line itself moves. At the bottom the line falls out directly;
  # at the top the student fills half the table first.
  helper_band = c.by_level([ 0..0, 0..1, 0..1, 0..5, 1..4, 2..5, 3..6 ])

  square = c.pick(ladybug_all(size))
  raise Authoring::Duplicate if ladybug_cyclic?(square)

  cells = (0...size).to_a.product((0...size).to_a)
  line, line_phrase, line_word =
    case target
    when :bottom then [ (0...size).map { |col| [ size - 1, col ] }, "най-долния ред", "ред" ]
    when :middle_row
      row = c.int(1..(size - 2))
      [ (0...size).map { |col| [ row, col ] }, "#{LADYBUG_ROWS_DEF[row]} ред отгоре", "ред" ]
    else
      col = c.int(0...size)
      [ (0...size).map { |row| [ row, col ] }, "#{LADYBUG_COLS_DEF[col]} колонка отляво", "колонка" ]
    end

  clue_cells = c.sample(cells, clue_count)
  asked = line - clue_cells
  # Two blanks is a puzzle; one is a formality. Leaving a clue or two inside the
  # asked line is what the printed original does, and it gives the student a
  # foothold — the top rungs do without it.
  raise Authoring::Duplicate unless asked_band.cover?(asked.size)

  clues = clue_cells.to_h { |row, col| [ [ row, col ], square[row][col] ] }

  # Does the question have exactly one answer? The grid as a whole may well have
  # several completions — it is the asked cells that have to be forced, and on a
  # 3x3 three clues pin the whole square anyway.
  fits = ladybug_all(size).select { |candidate| clues.all? { |(row, col), value| candidate[row][col] == value } }
  raise Authoring::Duplicate unless asked.all? { |row, col| fits.map { |candidate| candidate[row][col] }.uniq.size == 1 }

  chain = ladybug_chain(clues, size, asked)
  raise Authoring::Duplicate if chain.nil?
  raise Authoring::Duplicate unless helper_band.cover?(chain.size - asked.size)

  # The blanks are named by the coordinate that varies along the asked line.
  fields = asked.map do |row, col|
    line_word == "ред" ? [ "c#{col}", "#{LADYBUG_COLS[col]} колонка", square[row][col] ] :
                         [ "r#{row}", "#{LADYBUG_ROWS[row]} ред", square[row][col] ]
  end

  # The steps are the deductions the builder made, in the order it made them.
  # That order matters: each step cites what is *already* known, so reordering
  # them — printing every helper cell before the asked ones, say — can leave a
  # step citing a value the reader has not been given yet. A long chain is
  # compressed in the middle instead, where the reasoning is repetitive, keeping
  # the opening moves and the asked cells it ends on.
  conclude = ->((cell, value, reasoning)) { "#{reasoning}; остава калинката с #{ladybug_spots(value)}." }
  listing = ->(entries) { entries.map { |cell, value, _| "#{ladybug_cell_name(*cell)} — #{ladybug_spots(value)}" }.join("; ") }
  steps =
    if chain.size <= 6
      chain.map(&conclude)
    else
      head = chain.first(2)
      tail = (chain - head).select { |cell, _, _| asked.include?(cell) }.last(3)
      middle = chain - head - tail
      head.map(&conclude) +
        (middle.empty? ? [] : [ "По същото правило се нареждат и #{listing.call(middle)}." ]) +
        tail.map(&conclude)
    end

  c.q(
    text: "Във всяко квадратче на таблицата трябва да стои по една калинка с #{(1...size).to_a.join(', ')} или #{size} точки, " \
          "така че във всеки ред и във всяка колонка да няма две калинки с еднакъв брой точки. " \
          "Дадени са: #{clues.sort.map { |(row, col), value| "#{ladybug_cell_name(row, col)} — #{ladybug_spots(value)}" }.join('; ')}. " \
          "Колко точки има всяка от калинките на местата с въпросителен знак #{ladybug_in(line_phrase)}?",
    figure: Figures.ladybug_square(clues: clues, size: size, asked: asked),
    widget: WidgetKit.blanks(fields),
    # Three rungs, none of which is the answer: the rule, then where to start,
    # then the exclusions on the one cell the builder itself started from — the
    # student still has to work out what is left there.
    hints: [
      "В един ред и в една колонка не може да има две калинки с еднакъв брой точки.",
      "Започни от клетката, в която редът и колонката заедно забраняват най-много калинки — там остава само една възможност.",
      "Погледни #{chain.first[2].sub(':', ' —')}. Кой брой точки остава за тази клетка?"
    ],
    explanation: Explain.build(
      idea: "Латински квадрат с картинки: в един ред и в една колонка не може да има две калинки с еднакъв брой точки, " \
            "затова всяка празна клетка се намира по изключване, а не по проба.",
      steps: steps,
      answer: fields.map { |_, label, value| "#{label} — #{ladybug_spots(value)}" }.join(", "),
      check: "Заедно с дадените калинки #{line_word == 'ред' ? 'редът' : 'колонката'} съдържа " \
             "#{(1..size).to_a.join(', ')} — всеки брой точки точно по веднъж.",
      watch: "Проверява се едновременно редът и колонката: брой точки, който липсва в реда, " \
             "може вече да стои в колонката на същата клетка."
    )
  )
end
