# Неравенства на числовата ос: the student marks the solutions of an inequality
# on a line — where the boundary is, whether it belongs (a filled or an open
# dot) and which way the ray runs. Three separate decisions, and each family is
# built so that getting one of them wrong is a real possibility: the word
# problems test "поне" against "по-голямо от", the algebra tests the
# arithmetic, and the negative-coefficient family tests the flip.

module InequalityWork
  module_function

  RIGHT = %w[> ≥].freeze

  def direction(relation) = RIGHT.include?(relation) ? :right : :left
  def closed?(relation) = %w[≥ ≤].include?(relation)

  def flip(relation) = { ">" => "<", "<" => ">", "≥" => "≤", "≤" => "≥" }.fetch(relation)

  # A number in problem text: integer or half-integer, U+2212 minus, decimal comma.
  def num(value)
    r = Num.rat(value)
    r.denominator == 1 ? Num.bg(r) : Num.dec(r, 1).sub("-", Num::MINUS)
  end

  # The widget stores the edge as a plain number: an Integer, or a Float for a
  # half — YAML keeps both as they are and the checker compares floats.
  def edge_value(value)
    r = Num.rat(value)
    r.denominator == 1 ? r.to_i : r.to_f
  end

  # A line that holds the edge strictly inside and spans 13 ticks.
  def line_for(c, edge, step)
    ticks = 12
    before = c.int(3..(ticks - 3))
    min = Num.rat(edge) - (before * Num.rat(step))
    max = min + (ticks * Num.rat(step))
    { min: edge_value(min), max: edge_value(max), step: step == 1 ? 1 : step.to_f }
  end

  def widget(c, edge, relation, step: 1)
    line = line_for(c, edge, step)
    WidgetKit.inequality_line(edge: edge_value(edge), closed: closed?(relation), direction: direction(relation),
                              min: line[:min], max: line[:max], step: line[:step])
  end

  def describe(edge, relation)
    dot = closed?(relation) ? "плътна точка в #{num(edge)} (самото #{num(edge)} е решение)" : "празна точка в #{num(edge)} (самото #{num(edge)} не е решение)"
    ray = direction(relation) == :right ? "лъч надясно, към по-големите числа" : "лъч наляво, към по-малките числа"
    "#{dot} и #{ray}"
  end

  def dot_reason(edge, relation)
    if closed?(relation)
      "Знакът „#{relation}“ включва равенството, затова при x = #{num(edge)} неравенството е вярно и точката е плътна."
    else
      "Знакът „#{relation}“ е строг: при x = #{num(edge)} двете страни са равни, а това не стига — точката е празна."
    end
  end

  # A number on the ray, one step past the edge, to check with.
  def probe(edge, relation)
    Num.rat(edge) + (direction(relation) == :right ? 1 : -1)
  end
end

# ------------------------------------------------------------------ думи ---

Authoring.family "working.inequality.words", topic: "Неравенства", area: "interactive_working", variants: 9,
                 rungs: [ 1150, 1210, 1270, 1330, 1390, 1450 ] do |c|
  phrases = {
    ">" => [ "по-голямо от" ],
    "<" => [ "по-малко от" ],
    "≥" => [ "поне", "не по-малко от", "по-голямо или равно на" ],
    "≤" => [ "най-много", "не по-голямо от", "по-малко или равно на" ]
  }
  relation = c.pick(phrases.keys)
  pool = c.by_level([ [ 0 ], [ 0 ], [ 0, 1 ], [ 0, 1, 2 ], [ 1, 2 ], [ 1, 2 ] ])
  phrase = phrases[relation][[ c.pick(pool), phrases[relation].size - 1 ].min]
  edge = c.int(c.by_level([ 1..5, -2..6, -5..5, -6..6, -8..8, -9..9 ]))

  c.q(
    text: "Покажи на числовата ос всички числа x, за които x е #{phrase} #{InequalityWork.num(edge)}.",
    widget: InequalityWork.widget(c, edge, relation),
    explanation: Explain.build(
      idea: "Превеждаме думите в знак, после знакът казва каква е точката и накъде е лъчът.",
      steps: [
        "„x е #{phrase} #{InequalityWork.num(edge)}“ се записва x #{relation} #{InequalityWork.num(edge)}.",
        InequalityWork.dot_reason(edge, relation),
        InequalityWork.direction(relation) == :right ? "Решенията са числата вдясно от #{InequalityWork.num(edge)}." : "Решенията са числата вляво от #{InequalityWork.num(edge)}."
      ],
      answer: InequalityWork.describe(edge, relation),
      check: "Числото #{InequalityWork.num(InequalityWork.probe(edge, relation))} е на лъча и наистина е #{phrase} #{InequalityWork.num(edge)}.",
      watch: InequalityWork.closed?(relation) ? "„#{phrase}“ включва самото #{InequalityWork.num(edge)} — точката е плътна, не празна." : "„#{phrase}“ не включва самото #{InequalityWork.num(edge)} — точката е празна."
    ),
    hints: [
      "Запиши изречението със знак: >, <, ≥ или ≤.",
      "Решение ли е самото #{InequalityWork.num(edge)}? От това зависи дали точката е плътна."
    ]
  )
end

# --------------------------------------------------------------- x ± a ---

Authoring.family "working.inequality.shift", topic: "Неравенства", area: "interactive_working", variants: 9,
                 rungs: [ 1300, 1360, 1420, 1480, 1540, 1600 ] do |c|
  relation = c.pick(%w[> < ≥ ≤])
  edge = c.int(c.by_level([ 1..6, -3..6, -6..6, -8..8, -10..10, -12..12 ]))
  a = c.int(c.by_level([ 1..6, 2..9, 2..12, 3..15, 4..20, 5..30 ]))
  minus = c.by_level([ false, c.coin, c.coin, c.coin, true, c.coin ])
  # x + a ⋚ b, or x − a ⋚ b
  b = minus ? edge - a : edge + a
  left = minus ? "x #{Num::MINUS} #{a}" : "x + #{a}"
  move = minus ? "#{InequalityWork.num(b)} + #{a}" : "#{InequalityWork.num(b)} #{Num::MINUS} #{a}"

  c.q(
    text: "Покажи на числовата ос решенията на #{left} #{relation} #{InequalityWork.num(b)}.",
    widget: InequalityWork.widget(c, edge, relation),
    explanation: Explain.build(
      idea: "Както при уравнение: прехвърляме числото от другата страна, знакът на неравенството остава същият.",
      steps: [
        "#{left} #{relation} #{InequalityWork.num(b)}, значи x #{relation} #{move} = #{InequalityWork.num(edge)}.",
        InequalityWork.dot_reason(edge, relation),
        InequalityWork.direction(relation) == :right ? "Лъчът е надясно — x е по-голямо от границата." : "Лъчът е наляво — x е по-малко от границата."
      ],
      answer: "x #{relation} #{InequalityWork.num(edge)}: #{InequalityWork.describe(edge, relation)}",
      check: "При x = #{InequalityWork.num(InequalityWork.probe(edge, relation))}: #{minus ? "#{InequalityWork.num(InequalityWork.probe(edge, relation))} #{Num::MINUS} #{a}" : "#{InequalityWork.num(InequalityWork.probe(edge, relation))} + #{a}"} = #{InequalityWork.num(minus ? InequalityWork.probe(edge, relation) - a : InequalityWork.probe(edge, relation) + a)}, а то е #{relation} #{InequalityWork.num(b)}.",
      watch: minus ? "#{a} се прибавя към дясната страна, не се изважда." : "#{a} се изважда от дясната страна, не се прибавя."
    ),
    hints: [ "Остави x сам отляво, както при уравнение." ]
  )
end

# --------------------------------------------------------- ax + b, a > 0 ---

Authoring.family "working.inequality.linear", topic: "Неравенства", area: "interactive_working", variants: 9,
                 rungs: [ 1400, 1460, 1520, 1580, 1640, 1700 ] do |c|
  relation = c.pick(%w[> < ≥ ≤])
  a = c.int(c.by_level([ 2..3, 2..4, 2..5, 2..7, 3..9, 3..12 ]))
  edge = c.int(c.by_level([ 1..5, -2..6, -5..6, -6..6, -8..8, -9..9 ]))
  b = c.int(c.by_level([ 1..9, -9..12, -15..15, -20..20, -30..30, -40..40 ]))
  raise Authoring::Duplicate if b.zero?

  right = (a * edge) + b
  moved = right - b
  sign_b = b.negative? ? "+ #{b.abs}" : "#{Num::MINUS} #{b}"

  c.q(
    text: "Покажи на числовата ос решенията на #{Num.linear(a, b)} #{relation} #{InequalityWork.num(right)}.",
    widget: InequalityWork.widget(c, edge, relation),
    explanation: Explain.build(
      idea: "Решаваме като уравнение: първо махаме свободния член, после делим на коефициента пред x. Той е положителен, затова знакът не се обръща.",
      steps: [
        "#{a}x #{relation} #{InequalityWork.num(right)} #{sign_b} = #{InequalityWork.num(moved)}.",
        "Делим на #{a} > 0: x #{relation} #{InequalityWork.num(moved)} : #{a} = #{InequalityWork.num(edge)}.",
        InequalityWork.dot_reason(edge, relation)
      ],
      answer: "x #{relation} #{InequalityWork.num(edge)}: #{InequalityWork.describe(edge, relation)}",
      check: "При x = #{InequalityWork.num(InequalityWork.probe(edge, relation))}: #{a} · #{Num.signed(InequalityWork.probe(edge, relation))} #{b.negative? ? "#{Num::MINUS} #{b.abs}" : "+ #{b}"} = #{InequalityWork.num((a * InequalityWork.probe(edge, relation)) + b)}, а то е #{relation} #{InequalityWork.num(right)}.",
      watch: "Делението на положително число не обръща знака — обръща го само делението на отрицателно."
    ),
    hints: [
      "Махни свободния член от лявата страна.",
      "Раздели двете страни на коефициента пред x."
    ]
  )
end

# ----------------------------------------------------- a < 0: знакът се обръща ---

Authoring.family "working.inequality.flip", topic: "Неравенства", area: "interactive_working", variants: 9,
                 rungs: [ 1520, 1590, 1660, 1730, 1800, 1870 ] do |c|
  relation = c.pick(%w[> < ≥ ≤]) # as written, before dividing
  a = -c.int(c.by_level([ 1..2, 2..3, 2..4, 2..5, 2..7, 3..9 ]))
  edge = c.int(c.by_level([ 1..5, -3..5, -5..6, -6..6, -8..8, -9..9 ]))
  b = c.int(c.by_level([ 1..9, 1..12, -12..15, -20..20, -30..30, -40..40 ]))
  raise Authoring::Duplicate if b.zero?

  right = (a * edge) + b
  moved = right - b
  result = InequalityWork.flip(relation)
  # "5 − 2x" reads more naturally than "−2x + 5" — both appear, so the student
  # has to find the coefficient of x rather than the first number.
  left = c.coin && b.positive? ? "#{b} #{Num::MINUS} #{Num.monomial(a.abs, 'x')}" : Num.linear(a, b)
  sign_b = b.negative? ? "+ #{b.abs}" : "#{Num::MINUS} #{b}"

  c.q(
    text: "Покажи на числовата ос решенията на #{left} #{relation} #{InequalityWork.num(right)}.",
    widget: InequalityWork.widget(c, edge, result),
    explanation: Explain.build(
      idea: "Коефициентът пред x е отрицателен. Когато делим двете страни на отрицателно число, знакът на неравенството се обръща.",
      steps: [
        "#{Num.lead(a)} #{relation} #{InequalityWork.num(right)} #{sign_b} = #{InequalityWork.num(moved)}.",
        "Делим на #{InequalityWork.num(a)} < 0 и обръщаме знака: x #{result} #{InequalityWork.num(moved)} : #{Num.signed(a)} = #{InequalityWork.num(edge)}.",
        InequalityWork.dot_reason(edge, result)
      ],
      answer: "x #{result} #{InequalityWork.num(edge)}: #{InequalityWork.describe(edge, result)}",
      check: "При x = #{InequalityWork.num(InequalityWork.probe(edge, result))}: #{Num.signed(a)} · #{Num.signed(InequalityWork.probe(edge, result))} #{b.negative? ? "#{Num::MINUS} #{b.abs}" : "+ #{b}"} = #{InequalityWork.num((a * InequalityWork.probe(edge, result)) + b)}, а то е #{relation} #{InequalityWork.num(right)}.",
      watch: "Ако забравиш да обърнеш знака, лъчът ще сочи на обратната страна. Провери с едно число от лъча."
    ),
    hints: [
      "Остави члена с x сам отляво.",
      "На какво число делиш? Положително ли е?"
    ]
  )
end

# ------------------------------------------------------ граница на половинка ---

Authoring.family "working.inequality.halves", topic: "Неравенства", area: "interactive_working", variants: 9,
                 rungs: [ 1650, 1710, 1770, 1830, 1890, 1950 ] do |c|
  relation = c.pick(%w[> < ≥ ≤])
  a = c.by_level([ 2, 2, 2, c.pick([ 2, -2 ]), c.pick([ 2, 4, -2 ]), c.pick([ 2, 4, -2, -4 ]) ])
  edge = Rational((c.int(c.by_level([ 1..5, -3..5, -5..5, -6..6, -7..7, -8..8 ])) * 2) + 1, 2)
  raise Authoring::Duplicate unless (a * edge).denominator == 1

  b = c.int(c.by_level([ 1..9, -9..9, -12..12, -15..15, -20..20, -25..25 ]))
  raise Authoring::Duplicate if b.zero?

  right = ((a * edge) + b).to_i
  moved = right - b
  result = a.negative? ? InequalityWork.flip(relation) : relation
  sign_b = b.negative? ? "+ #{b.abs}" : "#{Num::MINUS} #{b}"

  c.q(
    text: "Покажи на числовата ос решенията на #{Num.linear(a, b)} #{relation} #{InequalityWork.num(right)}. Оста е разграфена през 0,5.",
    widget: InequalityWork.widget(c, edge, result, step: Rational(1, 2)),
    explanation: Explain.build(
      idea: "Решаваме както винаги; границата излиза между две цели числа, затова оста е разделена на половинки.",
      steps: [
        "#{Num.lead(a)} #{relation} #{InequalityWork.num(right)} #{sign_b} = #{InequalityWork.num(moved)}.",
        a.negative? ? "Делим на #{InequalityWork.num(a)} < 0 и обръщаме знака: x #{result} #{InequalityWork.num(moved)} : #{Num.signed(a)} = #{InequalityWork.num(edge)}." :
                      "Делим на #{a}: x #{result} #{InequalityWork.num(moved)} : #{a} = #{InequalityWork.num(edge)}.",
        InequalityWork.dot_reason(edge, result)
      ],
      answer: "x #{result} #{InequalityWork.num(edge)}: #{InequalityWork.describe(edge, result)}",
      check: "При x = #{InequalityWork.num(InequalityWork.probe(edge, result))} лявата страна е #{InequalityWork.num((a * InequalityWork.probe(edge, result)) + b)}, а то е #{relation} #{InequalityWork.num(right)}.",
      watch: a.negative? ? "Делим на отрицателно число — знакът се обръща." : "Границата е #{InequalityWork.num(edge)}, не най-близкото цяло число."
    ),
    hints: [ "Реши неравенството докрай — границата може да не е цяло число." ]
  )
end
