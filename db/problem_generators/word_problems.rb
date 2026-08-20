module ProblemGenerators
  # Applied word problems: movement, work, money, age. Each type is laddered
  # from a one-step intro to a competition-style multi-step version.
  module WordProblems
    extend self

    NAMES = %w[Мария Иван Петър Ана Георги Елена Никола Виктория Димитър Радост].freeze
    BOYS = %w[Иван Петър Георги Никола Димитър].freeze

    def generate
      problems = []
      problems += shopping
      problems += movement
      problems += work_rate
      problems += age
      problems += sharing
      problems
    end

    private

    def name_for(rng) = NAMES.sample(random: rng)
    def verb_for(name) = BOYS.include?(name) ? "купил" : "купила"
    def had_for(name) = BOYS.include?(name) ? "имал" : "имала"

    def shopping
      out = []
      rng = ProblemGenerators.rng("shop")

      # One-step: total cost.
      40.times do
        name = name_for(rng)
        count = rng.rand(2..9)
        price = rng.rand(2..12)
        out << ProblemGenerators.problem(
          text: "#{name} е #{verb_for(name)} #{count} тетрадки по #{price} лв. Колко лева е платила общо?",
          answer: count * price,
          topic: "Текстови задачи", grade: 2, tier: count <= 5 && price <= 5 ? :intro : :easy,
          explanation: "#{count} · #{price} = #{count * price} лв."
        )
      end

      # Two-step: change from a bill.
      35.times do
        name = name_for(rng)
        count = rng.rand(2..8)
        price = rng.rand(2..9)
        paid = [ 20, 50, 100 ].find { |bill| bill > count * price } || 100
        out << ProblemGenerators.problem(
          text: "#{name} е #{verb_for(name)} #{count} книжки по #{price} лв. и е платила с #{paid} лв. Колко лева ресто е получила?",
          answer: paid - count * price,
          topic: "Текстови задачи", grade: 3, tier: :medium,
          explanation: "Общата цена е #{count} · #{price} = #{count * price} лв. Рестото е #{paid} − #{count * price} = #{paid - count * price} лв."
        )
      end

      # Three-step: two kinds of items.
      30.times do
        name = name_for(rng)
        c1 = rng.rand(2..6)
        p1 = rng.rand(2..8)
        c2 = rng.rand(2..6)
        p2 = rng.rand(2..8)
        out << ProblemGenerators.problem(
          text: "#{name} е #{verb_for(name)} #{c1} моливa по #{p1} лв. и #{c2} гуми по #{p2} лв. Колко лева е платила общо?",
          answer: c1 * p1 + c2 * p2,
          topic: "Текстови задачи", grade: 4, tier: :medium,
          explanation: "Моливите: #{c1} · #{p1} = #{c1 * p1} лв. Гумите: #{c2} · #{p2} = #{c2 * p2} лв. Общо #{c1 * p1 + c2 * p2} лв."
        )
      end

      out
    end

    def movement
      out = []
      rng = ProblemGenerators.rng("move")

      # Distance = speed · time, all three directions.
      30.times do
        speed = [ 3, 4, 5, 6, 10, 12, 15, 20 ].sample(random: rng)
        time = rng.rand(2..8)
        out << ProblemGenerators.problem(
          text: "Колело се движи с #{speed} км/ч. Колко километра ще измине за #{time} часа?",
          answer: speed * time,
          topic: "Движение", grade: 4, tier: :easy,
          explanation: "Разстояние = скорост · време = #{speed} · #{time} = #{speed * time} км."
        )
      end

      25.times do
        speed = [ 4, 5, 6, 10, 12, 20 ].sample(random: rng)
        time = rng.rand(2..9)
        out << ProblemGenerators.problem(
          text: "Пешеходец изминава #{speed * time} км за #{time} часа. С каква скорост в км/ч се движи?",
          answer: speed,
          topic: "Движение", grade: 5, tier: :medium,
          explanation: "Скорост = разстояние : време = #{speed * time} : #{time} = #{speed} км/ч."
        )
      end

      25.times do
        speed = [ 5, 6, 10, 15, 20, 25 ].sample(random: rng)
        time = rng.rand(2..8)
        out << ProblemGenerators.problem(
          text: "Автомобил се движи с #{speed} км/ч и трябва да измине #{speed * time} км. За колко часа ще стигне?",
          answer: time,
          topic: "Движение", grade: 5, tier: :medium,
          explanation: "Време = разстояние : скорост = #{speed * time} : #{speed} = #{time} ч."
        )
      end

      # Two bodies approaching — the competition form, laddered by numbers.
      30.times do
        v1 = rng.rand(3..12)
        v2 = rng.rand(3..12)
        time = rng.rand(2..6)
        distance = (v1 + v2) * time
        out << ProblemGenerators.problem(
          text: "Две коли потеглят едновременно една срещу друга от градове на #{distance} км. Скоростите им са #{v1} км/ч и #{v2} км/ч. След колко часа ще се срещнат?",
          answer: time,
          topic: "Движение", grade: 6, tier: :hard,
          explanation: "Приближават се със #{v1} + #{v2} = #{v1 + v2} км всеки час. #{distance} : #{v1 + v2} = #{time} часа."
        )
      end

      20.times do
        v1 = rng.rand(4..10)
        v2 = v1 + rng.rand(2..8)
        time = rng.rand(2..6)
        out << ProblemGenerators.problem(
          text: "Двама тръгват от едно място в една посока. Първият се движи с #{v1} км/ч, вторият — с #{v2} км/ч. На колко километра един от друг ще са след #{time} часа?",
          answer: (v2 - v1) * time,
          topic: "Движение", grade: 6, tier: :competition,
          explanation: "Всеки час разстоянието между тях расте с #{v2} − #{v1} = #{v2 - v1} км. След #{time} часа: #{v2 - v1} · #{time} = #{(v2 - v1) * time} км."
        )
      end

      out
    end

    def work_rate
      out = []
      rng = ProblemGenerators.rng("work")

      # Intro: one worker, simple rate.
      30.times do
        rate = rng.rand(2..12)
        hours = rng.rand(2..8)
        out << ProblemGenerators.problem(
          text: "Работник сглобява #{rate} играчки на час. Колко играчки ще сглоби за #{hours} часа?",
          answer: rate * hours,
          topic: "Работа", grade: 4, tier: :easy,
          explanation: "#{rate} · #{hours} = #{rate * hours} играчки."
        )
      end

      25.times do
        workers = rng.rand(2..6)
        rate = rng.rand(2..8)
        hours = rng.rand(2..6)
        out << ProblemGenerators.problem(
          text: "#{workers} работници сглобяват по #{rate} играчки на час всеки. Колко играчки ще сглобят заедно за #{hours} часа?",
          answer: workers * rate * hours,
          topic: "Работа", grade: 5, tier: :medium,
          explanation: "За час всички правят #{workers} · #{rate} = #{workers * rate} играчки. За #{hours} часа: #{workers * rate} · #{hours} = #{workers * rate * hours}."
        )
      end

      # Inverse proportion — the classic competition twist.
      [ [ 2, 12 ], [ 3, 12 ], [ 4, 24 ], [ 6, 36 ], [ 5, 60 ] ].each do |workers, total_hours|
        new_workers = workers * 2
        out << ProblemGenerators.problem(
          text: "#{workers} работници свършват една работа за #{total_hours / workers} часа. За колко часа ще я свършат #{new_workers} работници (с еднаква производителност)?",
          answer: total_hours / new_workers,
          topic: "Работа", grade: 6, tier: :competition,
          explanation: "Цялата работа е #{total_hours} работник-часа. При #{new_workers} работници: #{total_hours} : #{new_workers} = #{total_hours / new_workers} часа. Повече работници — по-малко време."
        )
      end

      out
    end

    def age
      out = []
      rng = ProblemGenerators.rng("age")

      30.times do
        name = name_for(rng)
        age = rng.rand(6..14)
        diff = rng.rand(2..9)
        out << ProblemGenerators.problem(
          text: "#{name} е на #{age} години. Брат ѝ е с #{diff} години по-голям. На колко години е брат ѝ?",
          answer: age + diff,
          topic: "Текстови задачи", grade: 2, tier: :easy,
          explanation: "#{age} + #{diff} = #{age + diff} години."
        )
      end

      25.times do
        age = rng.rand(7..14)
        years = rng.rand(2..10)
        out << ProblemGenerators.problem(
          text: "Дете е на #{age} години. На колко години ще бъде след #{years} години?",
          answer: age + years,
          topic: "Текстови задачи", grade: 2, tier: :intro
        )
      end

      # Sum-and-difference — a genuinely competition-flavoured type, laddered.
      30.times do
        younger = rng.rand(5..20)
        diff = rng.rand(2..12)
        older = younger + diff
        out << ProblemGenerators.problem(
          text: "Двама братя имат общо #{younger + older} години. По-големият е с #{diff} години по-голям. На колко години е по-малкият?",
          answer: younger,
          topic: "Текстови задачи", grade: 5, tier: :hard,
          explanation: "Ако извадим разликата от сбора: #{younger + older} − #{diff} = #{2 * younger}. Това е двойно възрастта на по-малкия, значи той е #{younger} години."
        )
      end

      # Multiplicative age relations.
      25.times do
        child = rng.rand(4..12)
        factor = rng.rand(2..4)
        out << ProblemGenerators.problem(
          text: "Майка е #{factor} пъти по-възрастна от детето си, което е на #{child} години. С колко години майката е по-възрастна?",
          answer: child * factor - child,
          topic: "Текстови задачи", grade: 5, tier: :medium,
          explanation: "Майката е на #{child} · #{factor} = #{child * factor} години. Разликата е #{child * factor} − #{child} = #{child * factor - child} години."
        )
      end

      out
    end

    def sharing
      out = []
      rng = ProblemGenerators.rng("share")

      35.times do
        total = rng.rand(2..12) * rng.rand(2..9)
        people = (2..9).select { |p| total % p == 0 && total / p > 1 }.sample(random: rng)
        next if people.nil?

        out << ProblemGenerators.problem(
          text: "#{total} бонбона се разделят по равно между #{people} деца. По колко бонбона получава всяко дете?",
          answer: total / people,
          topic: "Текстови задачи", grade: 3, tier: :easy,
          explanation: "#{total} : #{people} = #{total / people} бонбона."
        )
      end

      # Sharing with a remainder — two-part answer trained as one question.
      30.times do
        people = rng.rand(3..9)
        each = rng.rand(2..12)
        left = rng.rand(1..(people - 1))
        total = people * each + left
        out << ProblemGenerators.problem(
          text: "#{total} ябълки се разделят по равно между #{people} деца. Колко ябълки остават неразделени?",
          answer: left,
          topic: "Текстови задачи", grade: 4, tier: :medium,
          explanation: "#{total} : #{people} = #{each} и остатък #{left}. Всяко дете взема #{each} ябълки, остават #{left}."
        )
      end

      # Unequal sharing — proportional reasoning.
      25.times do
        unit = rng.rand(2..10)
        ratio = rng.rand(2..4)
        total = unit + unit * ratio
        out << ProblemGenerators.problem(
          text: "#{total} стикера се разделят между две деца така, че първото да получи #{ratio} пъти повече от второто. Колко стикера получава второто дете?",
          answer: unit,
          topic: "Текстови задачи", grade: 6, tier: :hard,
          explanation: "Второто дете има 1 част, първото — #{ratio} части, общо #{ratio + 1} части. #{total} : #{ratio + 1} = #{unit} стикера за второто дете."
        )
      end

      out
    end
  end
end
