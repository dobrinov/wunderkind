module ProblemGenerators
  # Builds the topic tree, then imports every generated problem as a published
  # Question. Idempotent: problems are keyed by their plain-text body, so a
  # rerun updates instead of duplicating.
  module Importer
    extend self

    # Topic tree: roots are the curriculum areas, children the specific skills.
    # Prerequisites encode what the adaptive engine may unlock and when.
    TREE = {
      "Аритметика" => [ "Събиране и изваждане", "Умножение и деление", "Ред на действията" ],
      "Числа" => [ "Числа и редици", "Делимост", "Прости числа", "НОД и НОК", "Остатъци" ],
      "Дроби и проценти" => [ "Дроби", "Десетични числа", "Проценти" ],
      "Геометрия" => [ "Периметър", "Площ", "Ъгли", "Обем" ],
      "Логика" => [ "Броене и комбинаторика", "Логически задачи" ],
      "Задачи" => [ "Текстови задачи", "Движение", "Работа", "Уравнения" ]
    }.freeze

    PREREQUISITES = {
      "Умножение и деление" => [ "Събиране и изваждане" ],
      "Ред на действията" => [ "Умножение и деление" ],
      "Делимост" => [ "Умножение и деление" ],
      "Прости числа" => [ "Делимост" ],
      "НОД и НОК" => [ "Прости числа" ],
      "Остатъци" => [ "Делимост" ],
      "Дроби" => [ "Умножение и деление" ],
      "Десетични числа" => [ "Дроби" ],
      "Проценти" => [ "Десетични числа" ],
      "Площ" => [ "Периметър", "Умножение и деление" ],
      "Обем" => [ "Площ" ],
      "Ъгли" => [ "Събиране и изваждане" ],
      "Броене и комбинаторика" => [ "Умножение и деление" ],
      "Движение" => [ "Умножение и деление" ],
      "Работа" => [ "Умножение и деление" ],
      "Уравнения" => [ "Умножение и деление" ],
      "Текстови задачи" => [ "Събиране и изваждане" ]
    }.freeze

    # Resolved lazily: the generator files load in alphabetical order, so the
    # constants don't all exist yet when this file is read.
    GENERATOR_NAMES = %w[Arithmetic EarlyGrades Fractions Geometry MiddleGrades WordProblems Logic NumberTheory Interactive Variety].freeze

    def generators
      GENERATOR_NAMES.map { |name| ProblemGenerators.const_get(name) }
    end

    def run(verbose: true)
      topics = build_topics
      problems = collect_problems
      stats = import(problems, topics)
      stats.merge!(prune(problems))
      report(stats, problems) if verbose
      stats
    end

    # Retires generated problems that the generators no longer produce (a
    # template was capped or reworded). Anything a student has already answered
    # is unpublished rather than deleted, so their history stays intact.
    def prune(problems)
      wanted = problems.map { |problem| problem[:text] }.to_set
      stale = Question.where(author_id: nil).where.not(grade_min: nil).reject { |q| wanted.include?(q.body_text) }
      answered, unanswered = stale.partition { |question| question.user_answers.exists? }

      Question.where(id: unanswered.map(&:id)).destroy_all
      Question.where(id: answered.map(&:id)).update_all(status: Question.statuses[:draft])

      { pruned: unanswered.size, retired: answered.size }
    end

    def build_topics
      topics = {}

      TREE.each_with_index do |(root_name, children), root_index|
        root = Topic.find_or_create_by!(name: root_name) { |t| t.position = root_index }
        topics[root_name] = root

        children.each_with_index do |child_name, child_index|
          child = Topic.find_or_initialize_by(name: child_name)
          child.parent = root
          child.position = child_index
          child.save!
          topics[child_name] = child
        end
      end

      PREREQUISITES.each do |topic_name, prerequisite_names|
        topic = topics[topic_name]
        prerequisite_names.each do |prerequisite_name|
          next unless topics[prerequisite_name]

          TopicPrerequisite.find_or_create_by!(topic: topic, prerequisite: topics[prerequisite_name])
        end
      end

      topics
    end

    # A template that appears 180 times makes the bank feel like a worksheet.
    # Each problem *shape* (its text with the numbers collapsed) is capped, so
    # variety comes from having many kinds of problem rather than many
    # parameterisations of a few.
    SHAPE_CAP = 20

    # Core arithmetic drill genuinely benefits from volume — a child needs many
    # reps of the times table — so these shapes get a larger allowance.
    DRILL_SHAPE_CAP = 45
    DRILL_SHAPES = [ "# + # = ?", "# − # = ?", "# · # = ?", "# : # = ?" ].freeze

    def collect_problems
      # Dedupe on the question text: generators overlap deliberately (the same
      # skill shows up in several ladders) and the first occurrence wins.
      problems = generators.flat_map(&:generate).uniq { |problem| problem[:text] }
      cap_shapes(problems)
    end

    def shape_of(text)
      text.gsub(/\d+([.,]\d+)?/, "#").gsub(/\s+/, " ").strip
    end

    def cap_shapes(problems)
      problems.group_by { |problem| shape_of(problem[:text]) }.flat_map do |shape, group|
        cap = DRILL_SHAPES.include?(shape) ? DRILL_SHAPE_CAP : SHAPE_CAP
        next group if group.size <= cap

        # Thin evenly across the difficulty range so the shape keeps its ladder
        # instead of collapsing to whichever variants were generated first.
        sorted = group.sort_by { |problem| [ problem[:elo], problem[:text] ] }
        step = sorted.size.to_f / cap
        (0...cap).map { |index| sorted[(index * step).floor] }
      end
    end

    def import(problems, topics)
      stats = { created: 0, updated: 0, skipped: 0, by_topic: Hash.new(0), by_grade: Hash.new(0), by_tier: Hash.new(0) }
      existing = Question.where.not(body_text: nil).pluck(:body_text, :id).to_h

      problems.each_slice(500) do |batch|
        ActiveRecord::Base.transaction do
          batch.each do |problem|
            topic = topics[problem[:topic]]
            raise "Unknown topic #{problem[:topic]}" if topic.nil?

            question = existing[problem[:text]] ? Question.find(existing[problem[:text]]) : Question.new
            was_new = question.new_record?

            question.assign_attributes(
              body: RichContent.text_to_doc(problem[:text]),
              explanation: problem[:explanation],
              status: :published,
              elo: problem[:elo],
              **grade_band(problem),
              **answer_attributes(problem)
            )
            question.topics = [ topic ]

            if question.save
              was_new ? stats[:created] += 1 : stats[:updated] += 1
              stats[:by_topic][problem[:topic]] += 1
              stats[:by_grade][problem[:grade]] += 1
              stats[:by_tier][problem[:tier]] += 1
            else
              stats[:skipped] += 1
              warn "Skipped #{problem[:text].inspect}: #{question.errors.full_messages.join(', ')}"
            end
          end
        end
      end

      stats
    end

    # A competition-tier problem written on grade-4 material is not grade-4
    # work, so the harder tiers shift the band up. Keeps grade_min honest as
    # "youngest student who should see this", matching what the Elo implies.
    TIER_GRADE_BUMP = { intro: 0, easy: 0, medium: 0, hard: 1, competition: 1 }.freeze

    def grade_band(problem)
      minimum = (problem[:grade] + TIER_GRADE_BUMP.fetch(problem[:tier])).clamp(1, 7)
      { grade_min: minimum, grade_max: [ minimum + 2, 7 ].min }
    end

    def answer_attributes(problem)
      if problem[:widget]
        { answer_type: :interactive, grading: problem[:widget] }
      elsif problem[:options]
        { answer_type: :multiple_choice, grading: {} }.tap do |attrs|
          attrs[:possible_answers_attributes] = problem[:options].each_with_index.map do |option, index|
            { value: option, correct: option.to_s == problem[:answer], position: index + 1 }
          end
        end
      else
        { answer_type: :exact_value, grading: { "expected" => problem[:answer] } }
      end
    end

    def report(stats, problems)
      puts "\n=== Problem import ==="
      puts "Created: #{stats[:created]}  Updated: #{stats[:updated]}  Skipped: #{stats[:skipped]}" \
           "  Pruned: #{stats[:pruned]}  Retired (had answers): #{stats[:retired]}"
      puts "Total generated (deduped): #{problems.size}"

      puts "\nBy grade (elo range):"
      stats[:by_grade].sort.each do |grade, count|
        low = ProblemGenerators.elo_for(grade: grade, tier: :intro)
        high = ProblemGenerators.elo_for(grade: grade, tier: :competition)
        puts format("  Grade %d: %5d problems   elo %d–%d", grade, count, low, high)
      end

      puts "\nBy difficulty tier:"
      ProblemGenerators::TIERS.each do |tier|
        puts format("  %-12s %5d", tier, stats[:by_tier][tier].to_i)
      end

      puts "\nBy topic:"
      stats[:by_topic].sort_by { |_, count| -count }.each do |topic, count|
        puts format("  %-26s %5d", topic, count)
      end

      shapes = problems.group_by { |problem| shape_of(problem[:text]) }
      puts "\nVariety: #{shapes.size} distinct problem shapes, " \
           "largest cluster #{shapes.values.map(&:size).max}, " \
           "median #{shapes.values.map(&:size).sort[shapes.size / 2]}"
      puts
    end
  end
end
