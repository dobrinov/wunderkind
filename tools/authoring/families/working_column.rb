# Писмено събиране и изваждане в колонка.
#
# The column_arithmetic widget asks for the result digit by digit, with small
# cells over each column for the carry or the borrowed digit — so these
# families are about the written method, not the mental sum. The ladder climbs
# by what the method has to cope with: no carry, one carry, a carry in every
# column; no borrow, one borrow, a borrow across a zero. That last one is the
# classic: 504 − 267 asks for a borrow from a column that has nothing in it.

module ColumnWork
  PLACES = %w[единиците десетиците стотиците хилядите десетиците\ хиляди].freeze

  module_function

  def digits(number) = number.to_s.chars.reverse.map(&:to_i)

  def left_over(count) = count <= 1 ? "там остава #{count}" : "там остават #{count}"

  # Carries out of each column of a + b, ones first.
  def carries(a, b)
    da, db = digits(a), digits(b)
    carry = 0
    (0...[ da.size, db.size ].max).map do |i|
      carry = (da.fetch(i, 0) + db.fetch(i, 0) + carry) >= 10 ? 1 : 0
    end
  end

  # Columns of a − b that need a borrow, and whether any borrow has to reach
  # past a zero to find something to take.
  def borrows(a, b)
    top, bottom = digits(a), digits(b)
    needed = []
    across_zero = false
    top.each_index do |i|
      next unless top[i] < bottom.fetch(i, 0)

      needed << i
      j = i + 1
      j += 1 while top[j].zero?
      across_zero ||= j > i + 1
      top[j] -= 1
      ((i + 1)...j).each { |k| top[k] = 9 }
      top[i] += 10
    end
    [ needed, across_zero ]
  end

  def addition_steps(a, b)
    da, db = digits(a), digits(b)
    carry = 0
    width = [ da.size, db.size ].max
    steps = (0...width).map do |i|
      x, y = da.fetch(i, 0), db.fetch(i, 0)
      sum = x + y + carry
      parts = [ x, y ].join(" + ") + (carry.positive? ? " + 1 (пренос)" : "")
      line = "#{PLACES[i].capitalize}: #{parts} = #{sum}"
      line += sum >= 10 ? " — пишем #{sum % 10} и пренасяме 1 в #{PLACES[i + 1]}." : " — пишем #{sum}."
      carry = sum >= 10 ? 1 : 0
      line
    end
    steps << "Преносът от #{PLACES[width - 1]} става нова цифра отляво: пишем 1." if carry.positive?
    steps
  end

  def subtraction_steps(a, b)
    top, bottom = digits(a), digits(b)
    top.each_index.filter_map do |i|
      y = bottom.fetch(i, 0)
      next if i >= bottom.size && i == top.size - 1 && top[i].zero?

      prefix = "#{PLACES[i].capitalize}: "
      if top[i] < y
        j = i + 1
        j += 1 while top[j].zero?
        borrow = if j == i + 1
          "#{top[i]} − #{y} не може, затова заемаме 1 от #{PLACES[j]} (#{left_over(top[j] - 1)}): "
        else
          zeros = ((i + 1)...j).map { |k| PLACES[k] }.join(" и ")
          "#{top[i]} − #{y} не може, а в #{zeros} има 0 — заемаме от #{PLACES[j]} (#{left_over(top[j] - 1)}), " \
            "нулата в #{zeros} става 9: "
        end
        top[j] -= 1
        ((i + 1)...j).each { |k| top[k] = 9 }
        top[i] += 10
        "#{prefix}#{borrow}#{top[i]} − #{y} = #{top[i] - y}."
      elsif i >= bottom.size
        "#{prefix}отдолу няма цифра, сваляме #{top[i]}."
      else
        "#{prefix}#{top[i]} − #{y} = #{top[i] - y}."
      end
    end
  end
end

Authoring.family "working.column.addition", topic: "Събиране и изваждане", area: "interactive_working", variants: 10,
                 rungs: [ 650, 730, 820, 910, 990, 1070 ] do |c|
  # [digits of a, digits of b, how many columns carry]
  a_size, b_size, carry_count = c.by_level([ [ 2, 2, 0..0 ], [ 2, 2, 1..1 ], [ 3, 3, 1..1 ],
                                             [ 3, 3, 2..2 ], [ 4, 3, 2..3 ], [ 4, 4, 3..4 ] ])
  a = c.int((10**(a_size - 1))..((10**a_size) - 1))
  b = c.int((10**(b_size - 1))..((10**b_size) - 1))
  carries = ColumnWork.carries(a, b)
  raise Authoring::Duplicate unless carry_count.cover?(carries.sum)
  # One carry on the first rungs that carry means the ones column: that is the
  # first thing the method has to teach.
  raise Authoring::Duplicate if c.level.between?(1, 2) && carries.first.zero?

  sum = a + b
  c.q(
    text: "Събери в колонка: #{a} + #{b}.",
    widget: WidgetKit.column_arithmetic(operands: [ a, b ], op: "+"),
    explanation: Explain.build(
      idea: "Пишем числата едно под друго, единици под единици, и събираме колона по колона отдясно наляво.",
      steps: ColumnWork.addition_steps(a, b),
      answer: sum.to_s,
      check: "Изваждаме обратно: #{sum} − #{b} = #{a}.",
      watch: if carries.sum.zero?
        "Събираме цифрите от една и съща позиция — единици с единици, десетици с десетици."
             elsif c.top?
        "Пренос може да има във всяка колона, а последният става нова цифра отляво."
             else
        "Когато сборът в колона е 10 или повече, пишем само единиците му, а 1 пренасяме в следващата колона. Забравеният пренос е най-честата грешка."
             end
    ),
    hints: [
      "Започни от единиците: колко е #{ColumnWork.digits(a)[0]} + #{ColumnWork.digits(b)[0]}?",
      "Ако сборът в една колона е 10 или повече, напиши само единиците, а 1 пренеси в малката клетка над следващата колона."
    ]
  )
end

Authoring.family "working.column.subtraction", topic: "Събиране и изваждане", area: "interactive_working", variants: 10,
                 rungs: [ 700, 790, 880, 970, 1060, 1150 ] do |c|
  # [digits of a, digits of b, borrows, must a borrow cross a zero]
  a_size, b_size, borrow_count, across = c.by_level([ [ 2, 2, 0..0, false ], [ 2, 2, 1..1, false ], [ 3, 3, 1..1, false ],
                                                      [ 3, 3, 2..2, false ], [ 3, 3, 1..2, true ], [ 4, 4, 1..3, true ] ])
  a = c.int((10**(a_size - 1))..((10**a_size) - 1))
  # A borrow across a zero needs a zero to cross: put one in the tens (and,
  # on the top rung, sometimes the hundreds too).
  if across
    tens = ColumnWork.digits(a)
    tens[1] = 0
    tens[2] = 0 if a_size == 4 && c.coin
    a = tens.reverse.join.to_i
  end
  low, high = 10**(b_size - 1), [ a - 1, (10**b_size) - 1 ].min
  raise Authoring::Duplicate if high < low

  b = c.int(low..high)
  raise Authoring::Duplicate if b >= a || (a - b) < 10

  needed, crossed = ColumnWork.borrows(a, b)
  raise Authoring::Duplicate unless borrow_count.cover?(needed.size) && crossed == across
  raise Authoring::Duplicate if c.level.between?(1, 2) && needed.first != 0

  difference = a - b
  c.q(
    text: "Извади в колонка: #{a} − #{b}.",
    widget: WidgetKit.column_arithmetic(operands: [ a, b ], op: "−"),
    explanation: Explain.build(
      idea: "Пишем умаляемото отгоре, умалителя отдолу, единици под единици, и изваждаме колона по колона отдясно наляво.",
      steps: ColumnWork.subtraction_steps(a, b),
      answer: difference.to_s,
      check: "Събираме обратно: #{difference} + #{b} = #{a}.",
      watch: if needed.empty?
        "Изваждаме долната цифра от горната във всяка колона."
             elsif across
        "Когато в съседната колона има 0, заемаме от следващата — нулата става 9, а не 10."
             else
        "Не изваждай по-малката цифра от по-голямата, когато горната е по-малка (#{ColumnWork.digits(b)[needed.first]} − #{ColumnWork.digits(a)[needed.first]} е грешка) — заеми 1 от съседната колона."
             end
    ),
    hints: [
      "Започни от единиците: може ли да извадиш #{ColumnWork.digits(b)[0]} от #{ColumnWork.digits(a)[0]}?",
      "Ако горната цифра е по-малка, заеми 1 от съседната колона вляво и запиши в малката клетка какво е останало там."
    ]
  )
end
