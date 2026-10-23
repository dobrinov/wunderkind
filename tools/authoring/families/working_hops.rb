# Събиране и изваждане със скокове по числовата ос.
#
# The open number line is how mental addition is taught before the column
# method: 37 + 25 is a hop of twenty and a hop of five, and the student says
# where each hop lands. The widget offers only the hop sizes listed, so a
# change of 25 with sizes 1, 2, 5, 10 is two tens and a five — the split into
# tens and ones is the lesson. The landing number is written by the student;
# the widget never prints it.

module WorkingHops
  module_function

  # One way to make the change from the sizes on offer, biggest first.
  def decompose(amount, sizes)
    sizes.sort.reverse.each_with_object([]) do |size, hops|
      (amount / size).times { hops << size }
      amount %= size
    end
  end

  # The split a teacher would say aloud: hundreds, then tens, then ones.
  # „300, 30 и 6“ — commas, and „и“ before the last.
  def list(parts) = parts.size > 1 ? "#{parts[0..-2].join(', ')} и #{parts.last}" : parts.first.to_s

  def places(amount)
    [ 100, 10, 1 ].filter_map do |place|
      part = (amount / place) * place
      amount -= part
      part if part.positive?
    end
  end

  def problem(c, start:, change:, sizes:)
    end_value = start + change
    raise Authoring::Duplicate if end_value.negative? || change.zero?

    amount = change.abs
    sign = change.negative? ? Num::MINUS : "+"
    hops = decompose(amount, sizes).map { |size| size * (change.negative? ? -1 : 1) }
    raise Authoring::Duplicate if hops.size > 12

    position = start
    steps = places(amount).map do |part|
      from = position
      position += change.negative? ? -part : part
      "#{from} #{sign} #{part} = #{position}"
    end
    expression = "#{start} #{sign} #{amount}"
    split = places(amount)
    # A hint names the parts of the change; when one of them happens to be the
    # landing number (40 − 20), the hint would say the answer.
    raise Authoring::Duplicate if (split + [ amount ]).include?(end_value)

    c.q(
      text: "Пресметни със скокове по числовата ос: #{expression}.",
      widget: WidgetKit.number_hops(start: start, change: change, sizes: sizes, hops: hops),
      hints: [
        split.size > 1 ? "Разбий #{amount} на #{list(split)} и скачай на части." : "Скочи наведнъж или на по-малки скокове — общо #{amount}.",
        "Започни от #{start} и #{change.negative? ? 'скачай наляво' : 'скачай надясно'}."
      ],
      explanation: Explain.build(
        idea: split.size > 1 ? "Разбиваме #{amount} на #{split.join(' + ')} и #{change.negative? ? 'вадим' : 'добавяме'} на части, като отбелязваме къде стъпва всеки скок." :
                               "Скачаме #{amount} наведнъж или на по-малки скокове, като отбелязваме къде стъпва всеки скок.",
        steps: steps,
        answer: end_value.to_s,
        check: change.negative? ? "#{end_value} + #{amount} = #{start}" : "#{end_value} #{Num::MINUS} #{amount} = #{start}",
        watch: change.negative? ? "При изваждане се скача наляво — към по-малките числа. Щом минеш през кръгла десетица, броят на десетиците намалява." :
                                  "Когато сборът на единиците мине 10, десетиците се увеличават с една: следи къде стъпваш след кръглата десетица."
      )
    )
  end
end

Authoring.family "working.hops.add_within_100", topic: "Събиране и изваждане", area: "interactive_working", variants: 10,
                 rungs: [ 600, 660, 720, 780, 840, 900 ] do |c|
  start = c.int(c.by_level([ 10..40, 10..50, 15..60, 20..65, 25..70, 30..75 ]))
  change = c.int(c.by_level([ 2..9, 11..19, 12..29, 21..39, 23..49, 26..59 ]))
  # The upper rungs cross a ten in the ones, which is where the mistake lives.
  raise Authoring::Duplicate if c.level >= 3 && (start % 10) + (change % 10) < 10
  raise Authoring::Duplicate if start + change > 100

  WorkingHops.problem(c, start: start, change: change, sizes: [ 1, 2, 5, 10 ])
end

Authoring.family "working.hops.subtract_within_100", topic: "Събиране и изваждане", area: "interactive_working", variants: 10,
                 rungs: [ 650, 710, 770, 830, 890, 950 ] do |c|
  start = c.int(c.by_level([ 15..40, 25..60, 35..80, 40..90, 45..95, 50..99 ]))
  change = c.int(c.by_level([ 2..9, 11..19, 12..29, 21..39, 23..49, 26..59 ]))
  raise Authoring::Duplicate if c.level >= 3 && (start % 10) >= (change % 10)
  raise Authoring::Duplicate if start - change < 0

  WorkingHops.problem(c, start: start, change: -change, sizes: [ 1, 2, 5, 10 ])
end

Authoring.family "working.hops.three_digit", topic: "Събиране и изваждане", area: "interactive_working", variants: 10,
                 rungs: [ 850, 910, 970, 1030, 1090, 1150 ] do |c|
  start = c.int(c.by_level([ 100..400, 120..500, 150..600, 200..700, 200..800, 250..900 ]))
  change = c.int(c.by_level([ 100..300, 110..290, 120..350, 130..380, 140..390, 150..450 ]))
  sizes = c.level >= 3 ? [ 1, 5, 10, 50, 100 ] : [ 1, 10, 100 ]
  change = -change if c.coin
  raise Authoring::Duplicate if start + change.abs > 999 && change.positive?

  WorkingHops.problem(c, start: start, change: change, sizes: sizes)
end
