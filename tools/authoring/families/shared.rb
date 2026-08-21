# Shared props for the word problems: names, countable things, places.
#
# Bulgarian counts masculine nouns with a special form ("2 молива", not
# "2 моливи"), so every noun carries both forms and families ask for a count
# rather than pasting a plural.
module Props
  Item = Struct.new(:one, :many, :with) do
    # "3 молива", "1 молив"
    def count(n) = "#{n} #{n.abs == 1 ? one : many}"
  end

  NAMES = %w[Ани Борис Вяра Георги Дани Елена Живко Ива Калина Лора Мария Никола
             Огнян Петя Радост Симона Тодор Христо Цвета Явор].freeze

  # Things a child can count.
  THINGS = [
    Item.new("молив", "молива"), Item.new("тетрадка", "тетрадки"),
    Item.new("ябълка", "ябълки"), Item.new("банан", "банана"),
    Item.new("стикер", "стикера"), Item.new("книга", "книги"),
    Item.new("картичка", "картички"), Item.new("бонбон", "бонбона"),
    Item.new("орех", "ореха"), Item.new("топка", "топки"),
    Item.new("балон", "балона"), Item.new("камъче", "камъчета"),
    Item.new("значка", "значки"), Item.new("кубче", "кубчета")
  ].freeze

  # Things sold in a shop, with a plausible unit price band.
  GOODS = [
    [ Item.new("тетрадка", "тетрадки"), 1..4 ], [ Item.new("молив", "молива"), 1..3 ],
    [ Item.new("книга", "книги"), 6..18 ], [ Item.new("тениска", "тениски"), 12..30 ],
    [ Item.new("билет", "билета"), 3..12 ], [ Item.new("сладолед", "сладоледа"), 2..5 ],
    [ Item.new("чаша", "чаши"), 4..9 ], [ Item.new("раница", "раници"), 25..60 ]
  ].freeze

  CONTAINERS = [
    Item.new("кутия", "кутии"), Item.new("кашон", "кашона"), Item.new("торба", "торби"),
    Item.new("рафт", "рафта"), Item.new("кошница", "кошници"), Item.new("пакет", "пакета")
  ].freeze

  VEHICLES = [ "автомобил", "автобус", "влак", "велосипедист", "мотоциклет", "камион" ].freeze

  WORKERS = [ "работник", "печатар", "зидар", "бояджия", "градинар" ].freeze

  PLACES = [ "училището", "библиотеката", "магазина", "стадиона", "парка", "музея", "залата" ].freeze

  CLASSES = %w[5А 5Б 6А 6В 7А 7Б 4А 4В].freeze
end

# Bulgarian agrees the noun with the number: "1 година", but "2 години". The
# word problems get this from Props::Item#count, which carries both forms; this
# is for the nouns a family spells out in its own wording, where a rung of the
# ladder can legitimately be 1.
def count_noun(number, one, many)
  "#{number} #{number.abs == 1 ? one : many}"
end

# Pythagorean triples, generated from the primitives: a rung with six variants
# needs six triples in its size band, and the familiar handful (3-4-5, 5-12-13)
# runs out at once.
PRIMITIVE_TRIPLES = [ [ 3, 4, 5 ], [ 5, 12, 13 ], [ 8, 15, 17 ], [ 7, 24, 25 ], [ 20, 21, 29 ],
                      [ 9, 40, 41 ], [ 12, 35, 37 ], [ 28, 45, 53 ], [ 11, 60, 61 ], [ 33, 56, 65 ],
                      [ 16, 63, 65 ], [ 48, 55, 73 ], [ 13, 84, 85 ], [ 36, 77, 85 ], [ 39, 80, 89 ] ].freeze

TRIPLES = (1..8).flat_map { |k| PRIMITIVE_TRIPLES.map { |a, b, hyp| [ a * k, b * k, hyp * k ] } }.uniq.freeze

# A triple whose hypotenuse fits this rung's size band.
def pythagorean_triple(context)
  band = context.by_level([ 5..17, 10..30, 15..45, 25..70, 40..110, 60..200 ])
  candidates = TRIPLES.select { |_, _, hyp| band.include?(hyp) }
  raise Authoring::Duplicate if candidates.empty?

  context.pick(candidates)
end

module Authoring
  class Context
    def person = pick(Props::NAMES)

    # Two different people, for problems that compare.
    def people(count = 2) = sample(Props::NAMES, count)

    def thing = pick(Props::THINGS)

    def container = pick(Props::CONTAINERS)

    def goods = pick(Props::GOODS)

    def place = pick(Props::PLACES)

    # A cyclist does not travel at 140 km/h: the vehicle follows the speed.
    def vehicle_for(speed)
      if speed <= 25 then pick([ "велосипедист", "скутер", "трактор" ])
      elsif speed <= 60 then pick([ "автобус", "камион", "автомобил" ])
      else pick([ "автомобил", "влак", "мотоциклет", "автобус" ])
      end
    end

    def vehicle = pick(Props::VEHICLES)

    # Multiple-choice distractors: unique, in a stable order, always including
    # the right answer. Distractors are the answers a specific mistake gives —
    # never random numbers, or the wrong option teaches nothing.
    def options(correct, *wrong)
      list = ([ correct ] + wrong.flatten).map(&:to_s).uniq
      raise Duplicate if list.size < 3

      list.sort_by { |value| [ value.to_s.length, value.to_s ] }
    end
  end
end
