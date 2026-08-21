namespace :problems do
  desc "Import a problem file — or a directory of them — into the question bank (FILE=path, default db/seeds/problems.yml)"
  task import: :environment do
    path = Rails.root.join(ENV.fetch("FILE", ProblemSeeds::PROBLEMS_FILE))
    files = File.directory?(path) ? Dir[path.join("*.yml")].sort : [ path ]

    if files.none? { |file| File.exist?(file) }
      puts "No problem file at #{path} — nothing to import. Point FILE= at one, or author questions in the admin UI."
      next
    end

    topics = ProblemSeeds.import_topics(Rails.root.join(ProblemSeeds::TOPICS_FILE))
    totals = Hash.new(0)

    files.each do |file|
      stats = ProblemSeeds.import(YAML.safe_load_file(file).fetch("problems"), topics)
      stats.each { |key, count| totals[key] += count }
      puts format("%-40s %5d created, %5d updated, %4d skipped", File.basename(file), stats[:created], stats[:updated], stats[:skipped])
    end

    puts "Problems: #{totals[:created]} created, #{totals[:updated]} updated, #{totals[:skipped]} skipped"
    puts "Topics: #{Topic.count} (#{TopicPrerequisite.count} prerequisite edges)"
  end

  desc "Write the questions currently in the database out to db/seeds/problems.yml (and the topic tree to topics.yml)"
  task export: :environment do
    max = Integer(ENV.fetch("MAX_PER_SHAPE", ProblemSeeds::MAX_PER_SHAPE))
    written = ProblemSeeds.export(
      problems_path: Rails.root.join(ProblemSeeds::PROBLEMS_FILE),
      topics_path: Rails.root.join(ProblemSeeds::TOPICS_FILE),
      max_per_shape: max
    )

    puts "Wrote #{written} problems to #{ProblemSeeds::PROBLEMS_FILE} (max #{max} per shape)"
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
    # count("questions.id"), not count(*) — the latter counts the topic row
    # itself for topics with no questions.
    Topic.left_joins(:questions).group("topics.name").order(Arel.sql("count(questions.id) desc")).count("questions.id").each do |name, count|
      puts format("  %-26s %5d", name, count)
    end
    shapes = Question.published.pluck(:body_text).group_by { |t| ProblemSeeds.shape_of(t) }
    puts "\nVariety: #{shapes.size} shapes, largest cluster #{shapes.values.map(&:size).max || 0}"
  end
end
