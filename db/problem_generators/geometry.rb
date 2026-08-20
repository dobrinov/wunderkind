module ProblemGenerators
  # Perimeter, area, angles, and volume — grades 2-7.
  module Geometry
    extend self

    def generate
      problems = []
      problems += perimeter
      problems += area
      problems += angles
      problems += volume
      problems += counting_shapes
      problems
    end

    private

    def perimeter
      out = []
      rng = ProblemGenerators.rng("perim")

      # Squares are the on-ramp: one number in, one multiplication out.
      (2..20).each do |side|
        out << ProblemGenerators.problem(
          text: "Квадрат има страна #{side} см. Колко е периметърът му в сантиметри?", answer: side * 4,
          topic: "Периметър", grade: 2, tier: side <= 9 ? :intro : :easy,
          explanation: "Периметърът на квадрат е 4 · страната = 4 · #{side} = #{side * 4} см."
        )
      end

      35.times do
        a = rng.rand(2..25)
        b = rng.rand(2..25)
        next if a == b

        out << ProblemGenerators.problem(
          text: "Правоъгълник има страни #{a} см и #{b} см. Колко е периметърът му в сантиметри?",
          answer: 2 * (a + b),
          topic: "Периметър", grade: 3, tier: :easy,
          explanation: "P = 2 · (#{a} + #{b}) = 2 · #{a + b} = #{2 * (a + b)} см."
        )
      end

      # Inverse problems — competitions favour these.
      25.times do
        side = rng.rand(3..20)
        out << ProblemGenerators.problem(
          text: "Периметърът на квадрат е #{side * 4} см. Колко е страната му в сантиметри?", answer: side,
          topic: "Периметър", grade: 4, tier: :medium,
          explanation: "Страната е периметърът, разделен на 4: #{side * 4} : 4 = #{side} см."
        )
      end

      25.times do
        a = rng.rand(3..20)
        b = rng.rand(3..20)
        out << ProblemGenerators.problem(
          text: "Правоъгълник има периметър #{2 * (a + b)} см и една страна #{a} см. Колко е другата страна в сантиметри?",
          answer: b,
          topic: "Периметър", grade: 5, tier: :medium,
          explanation: "Полупериметърът е #{2 * (a + b)} : 2 = #{a + b} см. Другата страна е #{a + b} − #{a} = #{b} см."
        )
      end

      20.times do
        a = rng.rand(2..12)
        b = rng.rand(2..12)
        c = rng.rand([ (a - b).abs + 1, 2 ].max..(a + b - 1))
        out << ProblemGenerators.problem(
          text: "Триъгълник има страни #{a} см, #{b} см и #{c} см. Колко е периметърът му в сантиметри?",
          answer: a + b + c,
          topic: "Периметър", grade: 4, tier: :easy
        )
      end

      out
    end

    def area
      out = []
      rng = ProblemGenerators.rng("area")

      (2..20).each do |side|
        out << ProblemGenerators.problem(
          text: "Квадрат има страна #{side} см. Колко е лицето му в квадратни сантиметри?", answer: side * side,
          topic: "Площ", grade: 3, tier: side <= 10 ? :easy : :medium,
          explanation: "S = страна · страна = #{side} · #{side} = #{side * side} кв. см."
        )
      end

      35.times do
        a = rng.rand(2..20)
        b = rng.rand(2..20)
        out << ProblemGenerators.problem(
          text: "Правоъгълник има страни #{a} см и #{b} см. Колко е лицето му в квадратни сантиметри?",
          answer: a * b,
          topic: "Площ", grade: 3, tier: :easy,
          explanation: "S = #{a} · #{b} = #{a * b} кв. см."
        )
      end

      25.times do
        base = rng.rand(2..20)
        height = rng.rand(2..20)
        next unless (base * height) % 2 == 0

        out << ProblemGenerators.problem(
          text: "Триъгълник има основа #{base} см и височина #{height} см. Колко е лицето му в квадратни сантиметри?",
          answer: base * height / 2,
          topic: "Площ", grade: 5, tier: :medium,
          explanation: "S = основа · височина : 2 = #{base} · #{height} : 2 = #{base * height / 2} кв. см."
        )
      end

      # Area ↔ side, and the "double the side" trap.
      [ 4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144 ].each do |square|
        out << ProblemGenerators.problem(
          text: "Лицето на квадрат е #{square} кв. см. Колко е страната му в сантиметри?", answer: Integer.sqrt(square),
          topic: "Площ", grade: 5, tier: :medium,
          explanation: "Търсим число, което умножено по себе си дава #{square}: #{Integer.sqrt(square)} · #{Integer.sqrt(square)} = #{square}."
        )
      end

      (2..10).each do |side|
        out << ProblemGenerators.problem(
          text: "Квадрат има страна #{side} см. Ако удвоим страната, колко пъти се увеличава лицето?",
          answer: 4,
          topic: "Площ", grade: 6, tier: :competition,
          explanation: "Старото лице е #{side * side} кв. см, новото е #{2 * side} · #{2 * side} = #{4 * side * side} кв. см. Отношението е 4 — лицето расте с квадрата на увеличението."
        )
      end

      out
    end

    def angles
      out = []
      rng = ProblemGenerators.rng("angle")

      30.times do
        a = rng.rand(20..150)
        out << ProblemGenerators.problem(
          text: "Два ъгъла са съседни (сборът им е 180°). Единият е #{a}°. Колко градуса е другият?",
          answer: 180 - a,
          topic: "Ъгли", grade: 5, tier: :easy,
          explanation: "180° − #{a}° = #{180 - a}°."
        )
      end

      30.times do
        a = rng.rand(20..80)
        b = rng.rand(20..(160 - a))
        out << ProblemGenerators.problem(
          text: "В триъгълник два от ъглите са #{a}° и #{b}°. Колко градуса е третият ъгъл?",
          answer: 180 - a - b,
          topic: "Ъгли", grade: 6, tier: :medium,
          explanation: "Сборът на ъглите в триъгълник е 180°: 180° − #{a}° − #{b}° = #{180 - a - b}°."
        )
      end

      25.times do
        a = rng.rand(10..80)
        out << ProblemGenerators.problem(
          text: "Един ъгъл е #{a}°. Колко градуса е допълнителният му ъгъл до 90°?",
          answer: 90 - a,
          topic: "Ъгли", grade: 5, tier: :easy
        )
      end

      # Isosceles triangles — two-step reasoning.
      (20..80).step(5).each do |apex|
        base_angle = (180 - apex) / 2
        next unless (180 - apex) % 2 == 0

        out << ProblemGenerators.problem(
          text: "В равнобедрен триъгълник ъгълът при върха е #{apex}°. Колко градуса е всеки от ъглите при основата?",
          answer: base_angle,
          topic: "Ъгли", grade: 6, tier: :hard,
          explanation: "Двата ъгъла при основата са равни. Сборът им е 180° − #{apex}° = #{180 - apex}°, значи всеки е #{180 - apex} : 2 = #{base_angle}°."
        )
      end

      out
    end

    def volume
      out = []
      rng = ProblemGenerators.rng("vol")

      (2..12).each do |edge|
        out << ProblemGenerators.problem(
          text: "Куб има ръб #{edge} см. Колко е обемът му в кубични сантиметри?", answer: edge**3,
          topic: "Обем", grade: 6, tier: :medium,
          explanation: "V = #{edge} · #{edge} · #{edge} = #{edge**3} куб. см."
        )
      end

      30.times do
        a = rng.rand(2..12)
        b = rng.rand(2..12)
        c = rng.rand(2..12)
        out << ProblemGenerators.problem(
          text: "Правоъгълен паралелепипед има измерения #{a} см, #{b} см и #{c} см. Колко е обемът му в кубични сантиметри?",
          answer: a * b * c,
          topic: "Обем", grade: 6, tier: :medium,
          explanation: "V = #{a} · #{b} · #{c} = #{a * b * c} куб. см."
        )
      end

      (2..8).each do |edge|
        out << ProblemGenerators.problem(
          text: "Куб има ръб #{edge} см. Колко е повърхнината му в квадратни сантиметри?", answer: 6 * edge * edge,
          topic: "Обем", grade: 7, tier: :hard,
          explanation: "Кубът има 6 еднакви лица, всяко с лице #{edge} · #{edge} = #{edge * edge} кв. см. Общо 6 · #{edge * edge} = #{6 * edge * edge} кв. см."
        )
      end

      out
    end

    def counting_shapes
      out = []

      # How many squares in an n×n grid — a laddered competition classic.
      (2..6).each do |n|
        total = (1..n).sum { |k| (n - k + 1)**2 }
        grade = [ n + 1, 7 ].min
        out << ProblemGenerators.problem(
          text: "Колко квадрата (от всякакъв размер) има в мрежа #{n} × #{n}?", answer: total,
          topic: "Броене и комбинаторика", grade: grade, tier: :competition,
          explanation: "Квадратите 1×1 са #{n * n}, 2×2 са #{(n - 1)**2}#{n > 2 ? ", 3×3 са #{(n - 2)**2}" : ''} и така до #{n}×#{n}, който е 1. Общо #{total}."
        )
      end

      # Rectangles from a grid of lines — the 2×2 case is a warm-up, the 5×5
      # case is genuinely hard, so the rating has to track the size.
      (2..5).each do |n|
        total = (n * (n + 1) / 2)**2
        out << ProblemGenerators.problem(
          text: "Колко правоъгълника има в мрежа #{n} × #{n}?", answer: total,
          topic: "Броене и комбинаторика", grade: [ n + 2, 7 ].min, tier: n <= 2 ? :hard : :competition,
          explanation: "Избираме две от #{n + 1} вертикални линии и две от #{n + 1} хоризонтални: #{n * (n + 1) / 2} · #{n * (n + 1) / 2} = #{total}."
        )
      end

      out
    end
  end
end
