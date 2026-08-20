namespace :problems do
  SEED_FILE = Rails.root.join("db/seeds/problems.yml")

  desc "Load the curated problem set from db/seeds/problems.yml"
  task import: :environment do
    data = YAML.safe_load_file(SEED_FILE)
    topics = ProblemSeeds.build_topics(data.fetch("topics"), data.fetch("prerequisites"))
    stats = ProblemSeeds.import(data.fetch("problems"), topics)

    puts "Problems: #{stats[:created]} created, #{stats[:updated]} updated, #{stats[:skipped]} skipped"
    puts "Topics: #{Topic.count} (#{TopicPrerequisite.count} prerequisite edges)"
  end

  desc "Rewrite db/seeds/problems.yml from the questions currently in the database"
  task export: :environment do
    max = Integer(ENV.fetch("MAX_PER_SHAPE", ProblemSeeds::MAX_PER_SHAPE))
    written = ProblemSeeds.export(SEED_FILE, max_per_shape: max)

    puts "Wrote #{written} problems to #{SEED_FILE} (max #{max} per shape)"
  end

  desc "Report the distribution of the current question bank"
  task stats: :environment do
    puts "Questions: #{Question.count} (published: #{Question.published.count})"
    puts "\nBy elo band:"
    [ [ 0, 800 ], [ 800, 1000 ], [ 1000, 1200 ], [ 1200, 1400 ], [ 1400, 1600 ], [ 1600, 1800 ], [ 1800, 3000 ] ].each do |low, high|
      puts format("  %4d–%-4d %5d", low, high, Question.where(elo: low...high).count)
    end
    puts "\nBy answer type:"
    Question.group(:answer_type).count.each { |type, count| puts format("  %-16s %5d", type, count) }
    puts "\nBy topic:"
    Topic.left_joins(:questions).group("topics.name").order("count_all desc").count.each do |name, count|
      puts format("  %-26s %5d", name, count)
    end
    shapes = Question.published.pluck(:body_text).group_by { |t| ProblemSeeds.shape_of(t) }
    puts "\nVariety: #{shapes.size} shapes, largest cluster #{shapes.values.map(&:size).max}"
  end
end
