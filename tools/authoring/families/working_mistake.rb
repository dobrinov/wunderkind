# Намери грешката: a worked solution with exactly one wrong line.
#
# Every family here writes a solution the way a student would, makes one
# typical mistake on one line, and then carries on *correctly from the
# mistake* — so the lines after it are right for the wrong number and only one
# line is to blame. The mistake is not always on the first step: the lower
# rungs make it straight away, the higher ones do a step or two properly first,
# and where a rung allows it the mistake moves between lines from one variant
# to the next, because "the first line that looks odd" is not the same skill
# as "the first line that does not follow from the one above".
#
# Line 0 is the problem itself and is never the answer. The explanation says
# which line it is, what went wrong there, and what the solution comes to
# when it is done right.
require "set"

module MistakeKit
  module_function

  MINUS = Num::MINUS

  # Problems already written, per family. The text names a child as well, so
  # the builder's own duplicate check lets "Елена пресметна 3⁹ : 3³" and
  # "Огнян пресметна 3⁹ : 3³" both through — the same problem twice to a child
  # who meets both.
  SEEN = Hash.new { |hash, family| hash[family] = Set.new }

  def fresh!(family, problem)
    raise Authoring::Duplicate unless SEEN[family].add?(problem)
  end

  # A number inside a line: whole numbers plain, short decimals with a comma,
  # anything else as a fraction — always with the typographic minus.
  def n(value)
    r = Num.rat(value)
    return Num.bg(r) if r.denominator == 1

    Num.terminating?(r) ? Num.dec(r, 4).sub("-", MINUS) : Num.frac(r)
  end

  # An equation solved with a slip usually ends on an awkward number where the
  # right answer is whole — and that alone points at the mistake. Variants that
  # do are dropped.
  def whole!(value)
    raise Authoring::Duplicate unless Num.rat(value).denominator == 1
  end

  def ask(c, verb, problem)
    "#{c.person} #{verb} #{problem} и сбърка на един ред. На кой ред е грешката?"
  end

  # The lines must all differ, or "the line with the mistake" stops being one.
  def lines!(lines)
    raise Authoring::Duplicate if lines.uniq.size != lines.size || lines.size < 3

    lines
  end

  def answer(wrong, right)
    "грешката е на ред #{wrong}; решено вярно, се получава #{right}."
  end
end

# ---------------------------------------------------- Ред на действията ---

Authoring.family "working.mistake.order_of_operations", topic: "Ред на действията", area: "interactive_working", variants: 9,
                 rungs: [ 900, 960, 1020, 1080, 1140, 1200 ] do |c|
  watch = "Не смятай поред отляво надясно, без да гледаш кое е умножение — редът на действията решава."

  case c.level
  when 0
    a, b, k = c.int(2..9), c.int(2..9), c.int(2..9)
    problem = "#{a} + #{b} · #{k}"
    lines = [ problem, "= #{a + b} · #{k}", "= #{(a + b) * k}" ]
    wrong, right = 1, a + (b * k)
    fix = "#{b} · #{k} = #{b * k}, после #{a} + #{b * k} = #{right}"
    slip = "на ред 1 първо е събрано #{a} + #{b} = #{a + b}, а умножението трябва да е първо"
  when 1
    b, k = c.int(2..6), c.int(2..6)
    a = (b * k) + c.int(3..30)
    problem = "#{a} − #{b} · #{k}"
    lines = [ problem, "= #{a - b} · #{k}", "= #{(a - b) * k}" ]
    wrong, right = 1, a - (b * k)
    fix = "#{b} · #{k} = #{b * k}, после #{a} − #{b * k} = #{right}"
    slip = "на ред 1 първо е извадено #{a} − #{b} = #{a - b}, а умножението трябва да е първо"
  when 2
    late = c.coin
    a, b, x, d = c.int(2..9), c.int(2..9), c.int(2..9), c.int(2..9)
    product = a * b
    problem = "#{a} · #{b} + #{x} · #{d}"
    right = product + (x * d)
    fix = "#{a} · #{b} = #{product} и #{x} · #{d} = #{x * d}, после #{product} + #{x * d} = #{right}"
    if late
      lines = [ problem, "= #{product} + #{x} · #{d}", "= #{product + x} · #{d}", "= #{(product + x) * d}" ]
      wrong = 2
      slip = "ред 1 е верен, но на ред 2 е събрано #{product} + #{x} = #{product + x} преди умножението #{x} · #{d}"
    else
      lines = [ problem, "= #{a} · #{b + x} · #{d}", "= #{a * (b + x) * d}" ]
      wrong = 1
      slip = "на ред 1 първо е събрано #{b} + #{x} = #{b + x}, а двете умножения трябва да са първи"
    end
  when 3
    q, b, x, d = c.int(2..9), c.int(2..9), c.int(2..9), c.int(2..9)
    a = q * b
    e = c.int(1..q + (x * d) - 1)
    problem = "#{a} : #{b} + #{x} · #{d} − #{e}"
    lines = [ problem, "= #{q} + #{x} · #{d} − #{e}", "= #{q + x} · #{d} − #{e}", "= #{(q + x) * d} − #{e}", "= #{((q + x) * d) - e}" ]
    wrong, right = 2, q + (x * d) - e
    fix = "#{a} : #{b} = #{q} и #{x} · #{d} = #{x * d}, после #{q} + #{x * d} − #{e} = #{right}"
    slip = "делението на ред 1 е вярно, но на ред 2 е събрано #{q} + #{x} = #{q + x} преди умножението #{x} · #{d}"
  when 4
    a, b, x, d = c.int(2..20), c.int(2..9), c.int(2..9), c.int(2..9)
    sum = b + x
    problem = "#{a} + (#{b} + #{x}) · #{d}"
    right = a + (sum * d)
    fix = "скобите: #{b} + #{x} = #{sum}; после #{sum} · #{d} = #{sum * d}; накрая #{a} + #{sum * d} = #{right}"
    if c.coin
      lines = [ problem, "= #{a} + #{sum} · #{d}", "= #{a + sum} · #{d}", "= #{(a + sum) * d}" ]
      wrong = 2
      slip = "скобите на ред 1 са сметнати вярно, но на ред 2 е събрано #{a} + #{sum} = #{a + sum} преди умножението по #{d}"
    else
      lines = [ problem, "= #{a} + #{b} + #{x * d}", "= #{a + b + (x * d)}" ]
      wrong = 1
      slip = "на ред 1 скобите са изпуснати: по #{d} е умножено само #{x}, а трябва целият сбор #{b} + #{x}"
    end
  else
    a, b = c.int(3..9), c.int(4..9)
    product = a * b
    x, d = c.int(2..9), c.int(2..9)
    raise Authoring::Duplicate if x + d >= product

    problem = "#{a} · #{b} − #{x} + #{d}"
    right = product - x + d
    if c.coin
      lines = [ problem, "= #{product} − #{x} + #{d}", "= #{product} − #{x + d}", "= #{product - x - d}" ]
      wrong = 2
      slip = "на ред 2 е събрано #{x} + #{d} = #{x + d} и умалителят е станал по-голям — изваждането и събирането вървят отляво надясно"
      fix = "#{a} · #{b} = #{product}, после отляво надясно: #{product} − #{x} = #{product - x}, #{product - x} + #{d} = #{right}"
      watch = "Събирането и изваждането се правят поред отляво надясно — числата след минуса не се групират."
    else
      raise Authoring::Duplicate if x >= b

      lines = [ problem, "= #{a} · #{b - x} + #{d}", "= #{a * (b - x)} + #{d}", "= #{(a * (b - x)) + d}" ]
      wrong = 1
      slip = "на ред 1 първо е извадено #{b} − #{x} = #{b - x}, а умножението #{a} · #{b} трябва да е първо"
      fix = "#{a} · #{b} = #{product}, после #{product} − #{x} = #{product - x}, #{product - x} + #{d} = #{right}"
    end
  end

  raise Authoring::Duplicate if lines.last == "= #{right}"
  MistakeKit.fresh!("order_of_operations", problem)

  c.q(
    text: MistakeKit.ask(c, "пресметна", problem),
    widget: WidgetKit.find_mistake(lines: MistakeKit.lines!(lines), wrong: wrong),
    explanation: Explain.build(
      idea: "Първо се правят умножението и делението, после събирането и изваждането; действия от един вид — отляво надясно.",
      steps: [ "Грешката: #{slip}.", "Вярно е: #{fix}." ],
      answer: MistakeKit.answer(wrong, right),
      check: "Във вярното решение #{problem} = #{right}, а не #{lines.last.delete_prefix('= ')}.",
      watch: watch
    ),
    hints: [ "Кое действие в #{problem} се прави първо?", "Мини ред по ред и провери дали всяко действие е позволено да се направи точно тогава." ]
  )
end

# ---------------------------------------------------------------- Дроби ---

Authoring.family "working.mistake.adding_fractions", topic: "Дроби", area: "interactive_working", variants: 9,
                 rungs: [ 1100, 1160, 1220, 1280, 1340, 1400 ] do |c|
  coprime = lambda do |range|
    d = c.int(range)
    numerator = c.int(1...d)
    raise Authoring::Duplicate unless Num.gcd(numerator, d) == 1

    [ numerator, d ]
  end
  fr = ->(numerator, denominator) { "#{numerator}/#{denominator}" }

  case c.level
  when 0
    d = c.int(3..12)
    a, x = c.int(1...d), c.int(1...d)
    raise Authoring::Duplicate unless Num.gcd(a, d) == 1 && Num.gcd(x, d) == 1 && a != x

    problem = "#{fr.(a, d)} + #{fr.(x, d)}"
    lines = [ problem, "= (#{a} + #{x})/(#{d} + #{d})", "= #{Num.frac(a + x, 2 * d)}" ]
    wrong, right = 1, Rational(a + x, d)
    slip = "на ред 1 са събрани и знаменателите — при равни знаменатели се събират само числителите"
    fix = "#{problem} = #{fr.(a + x, d)}#{Rational(a + x, d).denominator == d ? '' : " = #{Num.bg(right)}"}"
    check = "#{Num.bg(right)} − #{fr.(x, d)} = #{fr.(a, d)} ✓"
    hint = "При равни знаменатели какво се събира — само числителите или и знаменателите?"
  when 1
    a, b = coprime.(2..6)
    x, d = coprime.(2..7)
    raise Authoring::Duplicate if b == d

    big = Num.lcm(b, d)
    problem = "#{fr.(a, b)} + #{fr.(x, d)}"
    lines = [ problem, "= (#{a} + #{x})/(#{b} + #{d})", "= #{Num.frac(a + x, b + d)}" ]
    wrong, right = 1, Rational(a, b) + Rational(x, d)
    slip = "на ред 1 са събрани числителите и знаменателите поотделно, а знаменателите първо трябва да станат равни"
    fix = "#{fr.(a, b)} = #{fr.(a * big / b, big)}, #{fr.(x, d)} = #{fr.(x * big / d, big)}, сборът е #{fr.(a * big / b + x * big / d, big)}"
    check = "#{Num.bg(right)} − #{fr.(x, d)} = #{fr.(a, b)} ✓"
    hint = "Може ли да се съберат дроби с различни знаменатели, преди да се приведат към общ знаменател?"
  when 2
    a, b = coprime.(2..8)
    x, d = coprime.(2..9)
    raise Authoring::Duplicate if b == d

    big = Num.lcm(b, d)
    top_a, top_x = a * big / b, x * big / d
    problem = "#{fr.(a, b)} + #{fr.(x, d)}"
    lines = [ problem, "= #{fr.(top_a, big)} + #{fr.(top_x, big)}", "= #{fr.(top_a + top_x, 2 * big)}" ]
    reduced = Rational(top_a + top_x, 2 * big)
    lines << "= #{Num.frac(reduced)}" if reduced.denominator != 2 * big
    wrong, right = 2, Rational(a, b) + Rational(x, d)
    slip = "ред 1 е верен (общият знаменател е #{big}), но на ред 2 са събрани и знаменателите"
    fix = "#{fr.(top_a, big)} + #{fr.(top_x, big)} = #{fr.(top_a + top_x, big)}"
    check = "#{Num.bg(right)} − #{fr.(x, d)} = #{fr.(a, b)} ✓"
    hint = "След като знаменателите станат равни, кое се събира?"
  when 3
    a, b = coprime.(2..8)
    x, d = coprime.(2..9)
    raise Authoring::Duplicate if b == d

    big = Num.lcm(b, d)
    problem = "#{fr.(a, b)} + #{fr.(x, d)}"
    lines = [ problem, "= #{fr.(a, big)} + #{fr.(x, big)}", "= #{fr.(a + x, big)}" ]
    reduced = Rational(a + x, big)
    lines << "= #{Num.frac(reduced)}" if reduced.denominator != big
    wrong, right = 1, Rational(a, b) + Rational(x, d)
    slip = "на ред 1 знаменателите са станали #{big}, но числителите не са умножени по същото число"
    fix = "#{fr.(a, b)} = #{fr.(a * big / b, big)} и #{fr.(x, d)} = #{fr.(x * big / d, big)}, сборът е #{fr.(a * big / b + x * big / d, big)}"
    check = "#{Num.bg(right)} − #{fr.(x, d)} = #{fr.(a, b)} ✓"
    hint = "Когато един знаменател се умножи по число, умножен ли е и числителят?"
  when 4
    # A difference that can be reduced is rare among random pairs, so the
    # pairs are drawn here until one is, rather than failing the attempt.
    pair = 60.times.lazy.filter_map do
      b, d = c.int(3..12), c.int(3..12)
      a, x = c.int(1...b), c.int(1...d)
      next if b == d || Num.gcd(a, b) != 1 || Num.gcd(x, d) != 1 || Rational(a, b) <= Rational(x, d)

      big = Num.lcm(b, d)
      diff = (a * big / b) - (x * big / d)
      g = Num.gcd(diff, big)
      [ a, b, x, d, big, diff, g ] if g > 1 && diff != g
    end.first
    raise Authoring::Duplicate unless pair

    a, b, x, d, big, diff, g = pair
    top_a, top_x = a * big / b, x * big / d

    problem = "#{fr.(a, b)} − #{fr.(x, d)}"
    lines = [ problem, "= #{fr.(top_a, big)} − #{fr.(top_x, big)}", "= #{fr.(diff, big)}", "= #{fr.(diff / g, big)}" ]
    wrong, right = 3, Rational(a, b) - Rational(x, d)
    slip = "редове 1 и 2 са верни, но на ред 3 числителят е разделен на #{g}, а знаменателят — не"
    fix = "#{fr.(diff, big)} = #{fr.(diff / g, big / g)}, като и числителят, и знаменателят се делят на #{g}"
    check = "#{Num.bg(right)} + #{fr.(x, d)} = #{fr.(a, b)} ✓"
    hint = "Когато дроб се съкращава, на какво се делят числителят и знаменателят?"
  else
    w1, w2 = c.int(1..4), c.int(1..4)
    n1, d1 = coprime.(2..6)
    n2, d2 = coprime.(2..6)
    raise Authoring::Duplicate if d1 == d2

    big = Num.lcm(d1, d2)
    bad = w2 + n2
    top1 = (w1 * d1) + n1
    problem = "#{w1} #{fr.(n1, d1)} + #{w2} #{fr.(n2, d2)}"
    lines = [ problem, "= #{fr.(top1, d1)} + #{fr.(bad, d2)}", "= #{fr.(top1 * big / d1, big)} + #{fr.(bad * big / d2, big)}",
              "= #{fr.((top1 * big / d1) + (bad * big / d2), big)}" ]
    wrong, right = 1, Rational(top1, d1) + Rational((w2 * d2) + n2, d2)
    slip = "на ред 1 смесеното число #{w2} #{fr.(n2, d2)} е превърнато в #{fr.(bad, d2)}: цялото е добавено към числителя, без да е умножено по знаменателя"
    fix = "#{w1} #{fr.(n1, d1)} = #{fr.(top1, d1)} и #{w2} #{fr.(n2, d2)} = #{fr.((w2 * d2) + n2, d2)}, а сборът е #{Num.mixed(right)}"
    check = "#{Num.mixed(right)} − #{w2} #{fr.(n2, d2)} = #{w1} #{fr.(n1, d1)} ✓"
    hint = "Как се превръща смесено число в неправилна дроб?"
  end

  raise Authoring::Duplicate if Num.rat(lines.last.delete_prefix("= ").tr(MistakeKit::MINUS, "-")) == right
  MistakeKit.fresh!("adding_fractions", problem)

  c.q(
    text: MistakeKit.ask(c, "пресметна", problem),
    widget: WidgetKit.find_mistake(lines: MistakeKit.lines!(lines), wrong: wrong),
    explanation: Explain.build(
      idea: "Дроби се събират и изваждат само с равни знаменатели: първо се привеждат към общ знаменател, после се събират числителите.",
      steps: [ "В #{problem} грешката: #{slip}.", "Вярно е: #{fix}." ],
      answer: MistakeKit.answer(wrong, Num.bg(right)),
      check: "С обратното действие: #{check}",
      watch: "Знаменателят казва на колко части е делено цялото — затова знаменателите не се събират."
    ),
    hints: [ "Провери на всеки ред: еднакви ли са знаменателите, преди числителите да се съберат?", hint ]
  )
end

# ------------------------------------------------------------ Уравнения ---

Authoring.family "working.mistake.brackets", topic: "Уравнения", area: "interactive_working", variants: 9,
                 rungs: [ 1200, 1260, 1320, 1380, 1440, 1500 ] do |c|
  n = MistakeKit.method(:n)
  x = c.int(1..9)

  case c.level
  when 0
    a = c.int(2..5)
    b = a * c.int(1..(9 / a))
    rhs = a * (x + b)
    problem = "#{a}(x + #{b}) = #{rhs}"
    lines = [ problem, "#{a}x + #{b} = #{rhs}", "#{a}x = #{rhs - b}", "x = #{n.(Rational(rhs - b, a))}" ]
    wrong = 1
    slip = "на ред 1 числото #{a} е умножено само по x, а по #{b} — не"
    fix = "#{a}x + #{a * b} = #{rhs}, #{a}x = #{rhs - (a * b)}, x = #{x}"
  when 1
    a = c.int(2..5)
    raise Authoring::Duplicate if (x - 1) / a < 1

    b = a * c.int(1..((x - 1) / a))
    rhs = a * (x - b)
    problem = "#{a}(x − #{b}) = #{rhs}"
    lines = [ problem, "#{a}x − #{b} = #{rhs}", "#{a}x = #{rhs + b}", "x = #{n.(Rational(rhs + b, a))}" ]
    wrong = 1
    slip = "на ред 1 числото #{a} е умножено само по x, а по #{b} — не"
    fix = "#{a}x − #{a * b} = #{rhs}, #{a}x = #{rhs + (a * b)}, x = #{x}"
  when 2
    total, b = c.int(15..40), c.int(1..9)
    rhs = total - x - b
    problem = "#{total} − (x + #{b}) = #{n.(rhs)}"
    if c.coin
      lines = [ problem, "#{total} − x + #{b} = #{n.(rhs)}", "#{total + b} − x = #{n.(rhs)}", "x = #{n.(total + b - rhs)}" ]
      wrong = 1
      slip = "на ред 1 минусът пред скобите е сменил знака само на x, а на #{b} — не"
    else
      lines = [ problem, "#{total} − x − #{b} = #{n.(rhs)}", "#{total + b} − x = #{n.(rhs)}", "x = #{n.(total + b - rhs)}" ]
      wrong = 2
      slip = "скобите на ред 1 са разкрити вярно, но на ред 2 #{total} − #{b} е сметнато като #{total + b}"
    end
    fix = "#{total} − x − #{b} = #{n.(rhs)}, #{total - b} − x = #{n.(rhs)}, x = #{x}"
  when 3
    a, k = c.int(2..5), c.int(2..4)
    if c.coin
      # The second bracket goes wrong; e is a multiple of what keeps the
      # mistaken x whole.
      step = (a + k) / Num.gcd(a + k, k - 1)
      raise Authoring::Duplicate if step > 20

      b, e = c.int(1..9), step * c.int(1..(20 / step))
      rhs = (a * (x + b)) + (k * (x - e))
      free = (a * b) - e
      raise Authoring::Duplicate if free.zero?

      problem = "#{a}(x + #{b}) + #{k}(x − #{e}) = #{n.(rhs)}"
      lines = [ problem, "#{a}x + #{a * b} + #{k}(x − #{e}) = #{n.(rhs)}", "#{a}x + #{a * b} + #{k}x − #{e} = #{n.(rhs)}",
                "#{Num.linear(a + k, free)} = #{n.(rhs)}", "#{a + k}x = #{n.(rhs - free)}", "x = #{n.(Rational(rhs - free, a + k))}" ]
      wrong = 2
      slip = "първите скоби на ред 1 са разкрити вярно, но на ред 2 числото #{k} е умножено само по x, а по #{e} — не"
    else
      # The first bracket goes wrong straight away.
      step = (a + k) / Num.gcd(a + k, a - 1)
      raise Authoring::Duplicate if step > 12

      b, e = step * c.int(1..(12 / step)), c.int(1..9)
      rhs = (a * (x + b)) + (k * (x - e))
      free = b - (k * e)
      raise Authoring::Duplicate if free.zero?

      problem = "#{a}(x + #{b}) + #{k}(x − #{e}) = #{n.(rhs)}"
      lines = [ problem, "#{a}x + #{b} + #{k}(x − #{e}) = #{n.(rhs)}", "#{a}x + #{b} + #{k}x − #{k * e} = #{n.(rhs)}",
                "#{Num.linear(a + k, free)} = #{n.(rhs)}", "#{a + k}x = #{n.(rhs - free)}", "x = #{n.(Rational(rhs - free, a + k))}" ]
      wrong = 1
      slip = "на ред 1 числото #{a} е умножено само по x, а по #{b} — не"
    end
    fix = "#{a}(x + #{b}) = #{a}x + #{a * b} и #{k}(x − #{e}) = #{k}x − #{k * e}, тогава #{Num.linear(a + k, (a * b) - (k * e))} = #{n.(rhs)} и x = #{x}"
  when 4
    a = c.int(3..6)
    step = (a - 1) / Num.gcd(a - 1, 2)
    b, e = c.int(1..9), step * c.int(1..(12 / step))
    rhs = (a * (x + b)) - (x - e)
    free = (a * b) - e
    raise Authoring::Duplicate if free.zero?

    problem = "#{a}(x + #{b}) − (x − #{e}) = #{n.(rhs)}"
    lines = [ problem, "#{a}x + #{a * b} − (x − #{e}) = #{n.(rhs)}", "#{a}x + #{a * b} − x − #{e} = #{n.(rhs)}",
              "#{Num.linear(a - 1, free)} = #{n.(rhs)}", "#{Num.lead(a - 1)} = #{n.(rhs - free)}", "x = #{n.(Rational(rhs - free, a - 1))}" ]
    wrong = 2
    slip = "на ред 2 минусът пред скобите (x − #{e}) е сменил знака на x, но не и на #{e}: трябва да е + #{e}"
    fix = "−(x − #{e}) = −x + #{e}, тогава #{Num.linear(a - 1, (a * b) + e)} = #{n.(rhs)} и x = #{x}"
  else
    k = c.int(2..4)
    a = c.int(k + 1..k + 4)
    step = (a - k) / Num.gcd(a - k, 2 * k)
    b, e = c.int(1..6), step * c.int(1..(9 / step))
    rhs = (a * (x - b)) - (k * (x + e))
    free = (k * e) - (a * b)
    raise Authoring::Duplicate if free.zero?

    problem = "#{a}(x − #{b}) − #{k}(x + #{e}) = #{n.(rhs)}"
    lines = [ problem, "#{a}x − #{a * b} − #{k}(x + #{e}) = #{n.(rhs)}", "#{a}x − #{a * b} − #{k}x + #{k * e} = #{n.(rhs)}",
              "#{Num.linear(a - k, free)} = #{n.(rhs)}", "#{Num.lead(a - k)} = #{n.(rhs - free)}", "x = #{n.(Rational(rhs - free, a - k))}" ]
    wrong = 2
    slip = "на ред 2 при разкриването на −#{k}(x + #{e}) вторият член трябва да е −#{k} · #{e} = −#{k * e}, а е записан + #{k * e}"
    fix = "−#{k}(x + #{e}) = −#{k}x − #{k * e}, тогава #{Num.linear(a - k, -(a * b) - (k * e))} = #{n.(rhs)} и x = #{x}"
  end

  raise Authoring::Duplicate if lines.last == "x = #{x}"
  MistakeKit.whole!(Num.rat(lines.last.delete_prefix("x = ").tr(",", ".").tr(MistakeKit::MINUS, "-")))
  MistakeKit.fresh!("brackets", problem)

  c.q(
    text: MistakeKit.ask(c, "реши уравнението", problem),
    widget: WidgetKit.find_mistake(lines: MistakeKit.lines!(lines), wrong: wrong),
    explanation: Explain.build(
      idea: "Число пред скоби умножава всяко събираемо в тях, а минус пред скоби сменя знака на всяко събираемо.",
      steps: [ "Грешката: #{slip}.", "Вярно е: #{fix}." ],
      answer: MistakeKit.answer(wrong, "x = #{x}"),
      check: "При x = #{x} лявата страна на #{problem} дава точно дясната; при #{lines.last} — не.",
      watch: "Числото или знакът пред скобите стига до всички членове в тях, не само до първия."
    ),
    hints: [ "Когато скобите се разкриват, умножава ли се всеки член в тях?", "Обърни внимание на знака пред скобите." ]
  )
end

Authoring.family "working.mistake.moving_terms", topic: "Уравнения", area: "interactive_working", variants: 9,
                 rungs: [ 1250, 1310, 1370, 1430, 1490, 1550 ] do |c|
  n = MistakeKit.method(:n)
  x = c.int(-6..9)
  raise Authoring::Duplicate if x.zero?

  # b is drawn from the multiples of `step` that fit, so that the mistaken
  # answer comes out whole like the right one.
  multiple = lambda do |step, range|
    choices = range.select { |value| (value % step).zero? }
    raise Authoring::Duplicate if choices.empty?

    c.pick(choices)
  end

  case c.level
  when 0
    b = c.int(2..20)
    rhs = x + b
    problem = "x + #{b} = #{n.(rhs)}"
    lines = [ problem, "x = #{n.(rhs)} + #{b}", "x = #{n.(rhs + b)}" ]
    wrong = 1
    slip = "на ред 1 числото #{b} е пренесено вдясно със същия знак, а трябваше да стане −#{b}"
    fix = "x = #{n.(rhs)} − #{b} = #{n.(x)}"
  when 1
    a = c.int(2..6)
    b = multiple.(a / Num.gcd(a, 2), 2..20)
    rhs = (a * x) + b
    problem = "#{a}x + #{b} = #{n.(rhs)}"
    lines = [ problem, "#{a}x = #{n.(rhs)} + #{b}", "#{a}x = #{n.(rhs + b)}", "x = #{n.(Rational(rhs + b, a))}" ]
    wrong = 1
    slip = "на ред 1 членът + #{b} е пренесен вдясно като + #{b}, а при пренасяне знакът се сменя"
    fix = "#{a}x = #{n.(rhs)} − #{b} = #{n.(rhs - b)}, x = #{n.(x)}"
  when 2
    a = c.int(2..6)
    b = multiple.(a / Num.gcd(a, 2), 2..20)
    rhs = (a * x) - b
    problem = "#{a}x − #{b} = #{n.(rhs)}"
    lines = [ problem, "#{a}x = #{n.(rhs)} − #{b}", "#{a}x = #{n.(rhs - b)}", "x = #{n.(Rational(rhs - b, a))}" ]
    wrong = 1
    slip = "на ред 1 членът − #{b} е пренесен вдясно като − #{b}, а при пренасяне знакът се сменя"
    fix = "#{a}x = #{n.(rhs)} + #{b} = #{n.(rhs + b)}, x = #{n.(x)}"
  when 3
    k = c.int(1..4)
    a = c.int(k + 1..k + 5)
    b = multiple.((a - k) / Num.gcd(a - k, 2), 2..15)
    d = (a * x) + b - (k * x)
    raise Authoring::Duplicate if d <= 0

    problem = "#{a}x + #{b} = #{Num.lead(k)} + #{d}"
    lines = [ problem, "#{a}x − #{Num.monomial(k, 'x')} + #{b} = #{d}", "#{a}x − #{Num.monomial(k, 'x')} = #{d} + #{b}",
              "#{Num.lead(a - k)} = #{d + b}", "x = #{n.(Rational(d + b, a - k))}" ]
    wrong = 2
    slip = "на ред 1 членът #{Num.monomial(k, 'x')} е пренесен вярно, но на ред 2 членът + #{b} е пренесен със същия знак"
    fix = "#{Num.lead(a - k)} = #{d} − #{b} = #{n.(d - b)}, x = #{n.(x)}"
  when 4
    k = c.int(1..4)
    a, b = c.int(k + 1..k + 5), c.int(2..15)
    d = (a * x) + b - (k * x)
    raise Authoring::Duplicate if d <= 0

    problem = "#{a}x + #{b} = #{Num.lead(k)} + #{d}"
    lines = [ problem, "#{a}x + #{Num.monomial(k, 'x')} = #{d} − #{b}", "#{Num.lead(a + k)} = #{n.(d - b)}", "x = #{n.(Rational(d - b, a + k))}" ]
    wrong = 1
    slip = "на ред 1 членът + #{b} е пренесен вярно като − #{b}, но членът #{Num.monomial(k, 'x')} е пренесен вляво със същия знак, а трябваше да стане −#{Num.monomial(k, 'x')}"
    fix = "#{a}x − #{Num.monomial(k, 'x')} = #{d} − #{b}, #{Num.lead(a - k)} = #{n.(d - b)}, x = #{n.(x)}"
  else
    a = c.int(2..6)
    b = c.int(10..30)
    rhs = b - (a * x)
    problem = "#{b} − #{a}x = #{n.(rhs)}"
    lines = [ problem, "#{MistakeKit::MINUS}#{a}x = #{n.(rhs)} − #{b}", "#{MistakeKit::MINUS}#{a}x = #{n.(rhs - b)}", "x = #{n.(Rational(rhs - b, a))}" ]
    wrong = 3
    slip = "редове 1 и 2 са верни, но на ред 3 #{MistakeKit::MINUS}#{a}x = #{n.(rhs - b)} е разделено на #{a}, а не на #{MistakeKit::MINUS}#{a}"
    fix = "x = #{n.(rhs - b)} : (#{MistakeKit::MINUS}#{a}) = #{n.(x)}"
  end

  raise Authoring::Duplicate if lines.last == "x = #{n.(x)}"
  MistakeKit.whole!(Num.rat(lines.last.delete_prefix("x = ").tr(",", ".").tr(MistakeKit::MINUS, "-")))
  MistakeKit.fresh!("moving_terms", problem)

  c.q(
    text: MistakeKit.ask(c, "реши уравнението", problem),
    widget: WidgetKit.find_mistake(lines: MistakeKit.lines!(lines), wrong: wrong),
    explanation: Explain.build(
      idea: "Член, който минава от едната страна на равенството на другата, сменя знака си. Когато делим, делим на целия коефициент пред x — заедно със знака му.",
      steps: [ "Грешката: #{slip}.", "Вярно е: #{fix}." ],
      answer: MistakeKit.answer(wrong, "x = #{n.(x)}"),
      check: "Заместваме x = #{n.(x)} в #{problem}: двете страни излизат равни.",
      watch: "Пренасянето е всъщност изваждане или събиране от двете страни — затова знакът се обръща."
    ),
    hints: [ "Когато член мине от другата страна на =, какво става със знака му?", "Провери всеки ред, като заместиш числото от последния ред в предишния." ]
  )
end

# ---------------------------------------------------- Степени и корени ---

Authoring.family "working.mistake.powers", topic: "Степени и корени", area: "interactive_working", variants: 9,
                 rungs: [ 1450, 1520, 1590, 1660, 1730, 1800 ] do |c|
  pw = ->(base, exponent) { Num.power(base, exponent) }

  case c.level
  when 0
    base, m, k = c.int(2..3), c.int(2..4), c.int(2..4)
    raise Authoring::Duplicate if m * k == m + k || base**(m * k) > 100_000

    if c.coin
      problem = "#{pw.(base, m)} · #{pw.(base, k)}"
      lines = [ problem, "= #{pw.(base, m * k)}", "= #{base**(m * k)}" ]
      wrong = 1
    else
      problem = "#{base**m} · #{pw.(base, k)}"
      lines = [ problem, "= #{pw.(base, m)} · #{pw.(base, k)}", "= #{pw.(base, m * k)}", "= #{base**(m * k)}" ]
      wrong = 2
    end
    right = base**(m + k)
    slip = "при умножение на степени с еднаква основа показателите са умножени, а трябва да се съберат"
    fix = "#{pw.(base, m)} · #{pw.(base, k)} = #{pw.(base, m + k)} = #{right}"
  when 1
    base, m, k = c.int(2..3), c.int(2..3), c.int(2..4)
    raise Authoring::Duplicate if m * k == m + k || base**(m * k) > 100_000

    if c.coin
      problem = "(#{pw.(base, m)})#{Num.sup(k)}"
      lines = [ problem, "= #{pw.(base, m + k)}", "= #{base**(m + k)}" ]
      wrong = 1
    else
      problem = "#{base**m}#{Num.sup(k)}"
      lines = [ problem, "= (#{pw.(base, m)})#{Num.sup(k)}", "= #{pw.(base, m + k)}", "= #{base**(m + k)}" ]
      wrong = 2
    end
    right = base**(m * k)
    slip = "при степенуване на степен показателите са събрани, а трябва да се умножат"
    fix = "(#{pw.(base, m)})#{Num.sup(k)} = #{pw.(base, m * k)} = #{right}"
  when 2
    base, k = c.int(2..3), c.int(2..3)
    m = k * c.int(2..3)
    raise Authoring::Duplicate if m / k == m - k

    if c.coin
      problem = "#{pw.(base, m)} : #{pw.(base, k)}"
      lines = [ problem, "= #{pw.(base, m / k)}", "= #{base**(m / k)}" ]
      wrong = 1
    else
      problem = "#{base**m} : #{pw.(base, k)}"
      lines = [ problem, "= #{pw.(base, m)} : #{pw.(base, k)}", "= #{pw.(base, m / k)}", "= #{base**(m / k)}" ]
      wrong = 2
    end
    right = base**(m - k)
    slip = "при деление на степени с еднаква основа показателите са разделени, а трябва да се извадят"
    fix = "#{pw.(base, m)} : #{pw.(base, k)} = #{pw.(base, m - k)} = #{right}"
  when 3
    a, b = c.int(2..9), c.int(2..9)
    if c.coin
      problem = "(#{a} + #{b})#{Num.sup(2)}"
      lines = [ problem, "= #{pw.(a, 2)} + #{pw.(b, 2)}", "= #{a * a} + #{b * b}", "= #{(a * a) + (b * b)}" ]
      wrong = 1
    else
      p, q = c.int(2..4), c.int(2..4)
      a = p * q
      problem = "(#{p} · #{q} + #{b})#{Num.sup(2)}"
      lines = [ problem, "= (#{a} + #{b})#{Num.sup(2)}", "= #{pw.(a, 2)} + #{pw.(b, 2)}", "= #{a * a} + #{b * b}", "= #{(a * a) + (b * b)}" ]
      wrong = 2
    end
    raise Authoring::Duplicate if a == b

    right = (a + b)**2
    slip = "квадратът на сбор е разписан като сбор на квадратите, а липсва удвоеното произведение 2 · #{a} · #{b}"
    fix = "(#{a} + #{b})#{Num.sup(2)} = #{pw.(a + b, 2)} = #{right}"
  when 4
    a, b, h = c.pick([ [ 3, 4, 5 ], [ 6, 8, 10 ], [ 5, 12, 13 ], [ 8, 15, 17 ], [ 9, 12, 15 ], [ 7, 24, 25 ], [ 12, 16, 20 ], [ 15, 20, 25 ], [ 20, 21, 29 ] ])
    a, b = b, a if c.coin
    if c.coin
      problem = "√(#{a * a} + #{b * b})"
      lines = [ problem, "= √#{a * a} + √#{b * b}", "= #{a} + #{b}", "= #{a + b}" ]
      wrong = 1
    else
      problem = "√(#{pw.(a, 2)} + #{pw.(b, 2)})"
      lines = [ problem, "= √(#{a * a} + #{b * b})", "= √#{a * a} + √#{b * b}", "= #{a} + #{b}", "= #{a + b}" ]
      wrong = 2
    end
    right = h
    slip = "коренът от сбор е разделен на сбор от корени, а така не може"
    fix = "√(#{a * a} + #{b * b}) = √#{h * h} = #{h}"
  else
    if c.coin
      a, k = c.int(2..9), c.int(10..90)
      problem = "#{MistakeKit::MINUS}#{pw.(a, 2)} + #{k}"
      lines = [ problem, "= #{a * a} + #{k}", "= #{(a * a) + k}" ]
      right = k - (a * a)
      slip = "#{MistakeKit::MINUS}#{pw.(a, 2)} е сметнато като (#{MistakeKit::MINUS}#{a})#{Num.sup(2)}, а степента се отнася само за #{a} и минусът остава"
      fix = "#{MistakeKit::MINUS}#{pw.(a, 2)} + #{k} = #{MistakeKit::MINUS}#{a * a} + #{k} = #{MistakeKit.n(right)}"
    else
      base, k = c.pick([ [ 2, 2 ], [ 2, 3 ], [ 3, 2 ], [ 4, 2 ], [ 5, 2 ] ])
      factor = (base**k) * c.int(1..5)
      problem = "#{factor} · #{base}#{Num.sup("-#{k}").tr('-', '⁻')}"
      lines = [ problem, "= #{factor} · (#{MistakeKit::MINUS}#{base**k})", "= #{MistakeKit::MINUS}#{factor * (base**k)}" ]
      right = factor / (base**k)
      slip = "отрицателният показател е превърнат в отрицателно число, а той значи деление: #{base}⁻#{Num.sup(k)} = 1 : #{pw.(base, k)}"
      fix = "#{factor} · #{base}⁻#{Num.sup(k)} = #{factor} : #{base**k} = #{right}"
    end
    wrong = 1
  end

  MistakeKit.fresh!("powers", problem)

  c.q(
    text: MistakeKit.ask(c, "пресметна", problem),
    widget: WidgetKit.find_mistake(lines: MistakeKit.lines!(lines), wrong: wrong),
    explanation: Explain.build(
      idea: "Правилата за степени: aᵐ · aⁿ = aᵐ⁺ⁿ, aᵐ : aⁿ = aᵐ⁻ⁿ, (aᵐ)ⁿ = aᵐⁿ; а квадрат и корен не се разпределят върху сбор.",
      steps: [ "В #{problem} грешката: #{slip}.", "Вярно е: #{fix}." ],
      answer: MistakeKit.answer(wrong, MistakeKit.n(right)),
      check: "Пресметни #{problem} направо, без правила: излиза #{MistakeKit.n(right)}, а не #{lines.last.delete_prefix('= ')}.",
      watch: "Правило за степени важи само за умножение и деление — със събиране не работи."
    ),
    hints: [ "Кое правило за степени е използвано на всеки ред? Вярно ли е записано?", "Пробвай реда с малки числа, например 2 и 3." ]
  )
end

# ---------------------------------------------------------- Неравенства ---

Authoring.family "working.mistake.inequality_sign", topic: "Неравенства", area: "interactive_working", variants: 9,
                 rungs: [ 1400, 1460, 1520, 1580, 1640, 1700 ] do |c|
  n = MistakeKit.method(:n)
  flip = { ">" => "<", "<" => ">", "≥" => "≤", "≤" => "≥" }
  sign = c.pick(flip.keys)
  minus = MistakeKit::MINUS
  hints = [ "На кой ред се дели или умножава с отрицателно число?", "Какво става със знака на неравенството при деление с отрицателно число?" ]
  # Where the mistake is a term moved without its sign changing, both
  # answers have an edge — and a whole right answer next to a fractional
  # wrong one would give the slip away.
  keep_whole = ->(right_edge, wrong_edge) { raise Authoring::Duplicate if right_edge.denominator == 1 && wrong_edge.denominator != 1 }

  case c.level
  when 0, 1
    a = c.level.zero? ? 1 : c.int(2..6)
    b, rhs = c.int(1..15), c.int(-10..20)
    d = rhs - b
    raise Authoring::Duplicate if d.zero?

    problem = "#{minus}#{Num.monomial(a, 'x')} + #{b} #{sign} #{n.(rhs)}"
    lines = [ problem, "#{minus}#{Num.monomial(a, 'x')} #{sign} #{n.(d)}", "x #{sign} #{n.(Rational(-d, a))}" ]
    wrong, right_sign, edge = 2, flip[sign], Rational(-d, a)
    slip = "на ред 2 двете страни са разделени на #{minus}#{a}, но знакът #{sign} не е обърнат"
  when 2
    a, b, rhs = c.int(2..6), c.int(5..25), c.int(-10..20)
    d = rhs - b
    raise Authoring::Duplicate if d.zero?

    problem = "#{b} − #{a}x #{sign} #{n.(rhs)}"
    right_sign, edge = flip[sign], Rational(-d, a)
    if c.coin
      lines = [ problem, "#{minus}#{a}x #{sign} #{n.(rhs)} − #{b}", "#{minus}#{a}x #{sign} #{n.(d)}", "x #{sign} #{n.(edge)}" ]
      wrong = 3
      slip = "редове 1 и 2 са верни, но на ред 3 при делението на #{minus}#{a} знакът #{sign} не е обърнат"
    else
      keep_whole.(edge, Rational(-(rhs + b), a))
      lines = [ problem, "#{minus}#{a}x #{sign} #{n.(rhs)} + #{b}", "#{minus}#{a}x #{sign} #{n.(rhs + b)}", "x #{flip[sign]} #{n.(Rational(-(rhs + b), a))}" ]
      wrong = 1
      slip = "на ред 1 числото #{b} е пренесено вдясно със същия знак, а трябваше да стане −#{b}"
    end
  when 3
    a = c.int(1..4)
    k = c.int(a + 1..a + 5)
    b, d = c.int(1..15), c.int(1..15)
    raise Authoring::Duplicate if b == d

    problem = "#{Num.lead(a)} + #{b} #{sign} #{Num.lead(k)} + #{d}"
    right_sign, edge = flip[sign], Rational(d - b, a - k)
    if c.coin
      lines = [ problem, "#{Num.lead(a)} − #{Num.monomial(k, 'x')} #{sign} #{d} − #{b}", "#{Num.lead(a - k)} #{sign} #{n.(d - b)}",
                "x #{sign} #{n.(edge)}" ]
      wrong = 3
      slip = "до ред 2 всичко е вярно, но на ред 3 при делението на #{n.(a - k)} знакът #{sign} не е обърнат"
    else
      keep_whole.(edge, Rational(d + b, a - k))
      lines = [ problem, "#{Num.lead(a)} − #{Num.monomial(k, 'x')} #{sign} #{d} + #{b}", "#{Num.lead(a - k)} #{sign} #{n.(d + b)}",
                "x #{flip[sign]} #{n.(Rational(d + b, a - k))}" ]
      wrong = 1
      slip = "на ред 1 членът + #{b} е пренесен вдясно със същия знак, а трябваше да стане −#{b}"
    end
  when 4
    a, b, rhs = c.int(2..6), c.int(1..15), c.int(-10..25)
    raise Authoring::Duplicate if rhs == b

    problem = "#{a}x + #{b} #{sign} #{n.(rhs)}"
    lines = [ problem, "#{a}x #{flip[sign]} #{n.(rhs)} − #{b}", "#{a}x #{flip[sign]} #{n.(rhs - b)}", "x #{flip[sign]} #{n.(Rational(rhs - b, a))}" ]
    wrong, right_sign, edge = 1, sign, Rational(rhs - b, a)
    slip = "на ред 1 знакът #{sign} е обърнат, а при изваждане на #{b} от двете страни той остава същият — обръща се само при умножение или деление с отрицателно число"
    hints = [ "Кога се обръща знакът на неравенство — при изваждане или при деление с отрицателно число?",
              "Мини ред по ред: какво е направено с двете страни и трябваше ли знакът да се смени?" ]
  else
    k, b, rhs = c.int(2..5), c.int(1..8), c.int(-10..20)
    d = rhs - (k * b)
    raise Authoring::Duplicate if d.zero?

    problem = "#{k}(#{b} − x) #{sign} #{n.(rhs)}"
    right_sign, edge = flip[sign], Rational(-d, k)
    if c.coin
      lines = [ problem, "#{k * b} − #{k}x #{sign} #{n.(rhs)}", "#{minus}#{k}x #{sign} #{n.(d)}", "x #{sign} #{n.(edge)}" ]
      wrong = 3
      slip = "скобите и пренасянето са верни, но на ред 3 при делението на #{minus}#{k} знакът #{sign} не е обърнат"
    else
      shortened = rhs - (k * b)
      lines = [ problem, "#{k * b} − x #{sign} #{n.(rhs)}", "#{minus}x #{sign} #{n.(shortened)}", "x #{flip[sign]} #{n.(-shortened)}" ]
      wrong = 1
      slip = "на ред 1 числото #{k} е умножено само по #{b}, а по x — не: трябва да е #{k * b} − #{k}x"
    end
  end

  right = "x #{right_sign} #{n.(edge)}"
  raise Authoring::Duplicate if lines.last == right
  MistakeKit.fresh!("inequality_sign", problem)

  mistaken_sign, mistaken_edge = lines.last.delete_prefix("x ").split(" ", 2)
  words = ->(relation, value) { %w[> ≥].include?(relation) ? "по-голямо от #{value}" : "по-малко от #{value}" }
  tail = mistaken_edge == n.(edge) ? "не е решение" : "не винаги е решение"

  c.q(
    text: MistakeKit.ask(c, "реши неравенството", problem),
    widget: WidgetKit.find_mistake(lines: MistakeKit.lines!(lines), wrong: wrong),
    explanation: Explain.build(
      idea: "Неравенство се решава като уравнение, с едно изключение: при умножение или деление на отрицателно число знакът се обръща.",
      steps: [ "Грешката: #{slip}.", "Вярно е: #{right}." ],
      answer: MistakeKit.answer(wrong, right),
      check: "Вземи число, #{words.(right_sign, n.(edge))}, и го замести в #{problem} — неравенството е вярно. Число, #{words.(mistaken_sign, mistaken_edge)}, #{tail}.",
      watch: "Събирането и изваждането никога не обръщат знака на неравенство; делението на отрицателно число — винаги."
    ),
    hints: hints
  )
end
