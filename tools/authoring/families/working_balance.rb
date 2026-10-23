# Уравнения на везна.
#
# The equation is drawn as two pans: x boxes and unit weights. The student
# solves it by doing the same thing to both pans — take weights off, take x
# boxes off, split both into equal parts — and then writes what x is. The moves
# are their working; the value written is what is graded.
#
# Every pan holds at most 6 boxes and 60 weights (the widget draws tens as bars),
# x is a positive whole number, and `steps` is one legal way to solve it, which
# check.rb replays on the pans.

module BalanceText
  module_function

  # "3x + 2", "x", "11" — the same words the widget and the grader use.
  def side(xs, units)
    terms = []
    terms << (xs == 1 ? "x" : "#{xs}x") if xs.positive?
    terms << units.to_s if units.positive? || terms.empty?
    terms.join(" + ")
  end

  def equation(left, right) = "#{side(*left)} = #{side(*right)}"

  # The pans after one move, on both sides — so an explanation can write each
  # step the way round the problem was written, „42 = 4x + 14“ → „28 = 4x“.
  def apply(pans, op, k)
    pans.map do |xs, units|
      case op
      when :x then [ xs - k, units ]
      when :units then [ xs, units - k ]
      else [ xs / k, units / k ]
      end
    end
  end

  # One sentence per move, each ending on the equation it leaves.
  def moves(pans, steps)
    steps.map do |op, k|
      pans = apply(pans, op, k)
      what = case op
      when :x then "Махаме #{side(k, 0)} от двете страни"
      when :units then "Махаме #{k} от двете страни"
      else "Разделяме двете страни на #{k}"
      end
      "#{what}: #{equation(*pans)}."
    end
  end
end

Authoring.family "working.balance.one_side", topic: "Уравнения", area: "interactive_working", variants: 10,
                 rungs: [ 900, 980, 1060, 1140, 1220, 1300 ] do |c|
  # Each rung at least as hard as the one below: x alone, then 2x, then 2x or
  # 3x with more weights, then 3x and 4x.
  a = c.int(c.by_level([ 1..1, 2..2, 2..3, 3..3, 3..4, 4..4 ]))
  x = c.int(c.by_level([ 2..9, 2..9, 3..9, 3..12, 4..12, 4..13 ]))
  b = c.int(c.by_level([ 1..9, 2..9, 3..12, 3..15, 5..15, 5..12 ]))
  total = a * x + b
  raise Authoring::Duplicate if total > 60

  left, right = [ a, b ], [ 0, total ]
  left, right = right, left if c.level >= 4 && c.coin
  steps = [ [ :units, b ] ]
  steps << [ :divide, a ] if a > 1

  moves = BalanceText.moves([ left, right ], steps)

  c.q(
    text: "Реши с везната: #{BalanceText.equation(left, right)}.",
    widget: WidgetKit.balance_scale(left: left, right: right, x: x, steps: steps),
    explanation: Explain.build(
      idea: "Везната остава в равновесие, ако направим едно и също и от двете страни. Целта е x да остане сам.",
      steps: moves,
      answer: "x = #{x}",
      check: "#{a == 1 ? x : "#{a} · #{x}"} + #{b} = #{total} ✓",
      watch: a > 1 ? "Първо махаме теглилките, после делим. Ако разделим само x на #{a}, везната вече не е в равновесие." :
                     "Теглилките се махат и от двете страни — иначе везната се накланя."
    ),
    hints: [ "Колко теглилки са до x? Махни толкова и от двете страни." ] +
           (a > 1 ? [ "Щом останат само x-ове срещу теглилки, раздели двете страни на броя на x-овете." ] : [])
  )
end

Authoring.family "working.balance.both_sides", topic: "Уравнения", area: "interactive_working", variants: 10,
                 rungs: [ 1100, 1170, 1240, 1310, 1380, 1450 ] do |c|
  more = c.int(c.by_level([ 2..3, 2..3, 2..4, 3..5, 3..6, 4..6 ]))
  less = c.int(1...more)
  x = c.int(c.by_level([ 2..6, 2..8, 2..9, 3..10, 3..12, 4..12 ]))
  b = c.int(c.by_level([ 1..5, 1..8, 1..10, 1..12, 2..15, 2..18 ]))
  d = (more - less) * x + b
  raise Authoring::Duplicate if d > 60 || more * x + b > 60

  big, small = [ more, b ], [ less, d ]
  left, right = c.level >= 2 && c.coin ? [ small, big ] : [ big, small ]
  steps = [ [ :x, less ], [ :units, b ] ]
  steps << [ :divide, more - less ] if more - less > 1
  rest = more - less

  moves = BalanceText.moves([ left, right ], steps)

  c.q(
    text: "Реши с везната: #{BalanceText.equation(left, right)}.",
    widget: WidgetKit.balance_scale(left: left, right: right, x: x, steps: steps),
    explanation: Explain.build(
      idea: "Когато x има и от двете страни, първо махаме еднакъв брой x-ове и от двете страни, после теглилките, после делим.",
      steps: moves,
      answer: "x = #{x}",
      check: "#{more} · #{x} + #{b} = #{more * x + b} и #{less} · #{x} + #{d} = #{less * x + d} ✓",
      watch: "Махаме #{less == 1 ? 'x' : "#{less}x"} и от двете страни. Ако махнем x само от едната, уравнението вече е друго."
    ),
    hints: [
      "На коя страна има по-малко x-ове? Махни толкова x и от двете страни.",
      "После махни теглилките, които стоят до x."
    ]
  )
end
