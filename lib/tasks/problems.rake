namespace :problems do
  desc "Generate and import the original problem database (topics, prerequisites, questions)"
  task generate: :environment do
    Dir[Rails.root.join("db/problem_generators/base.rb")].each { |file| require file }
    Dir[Rails.root.join("db/problem_generators/*.rb")].sort.each { |file| require file }

    ProblemGenerators::Importer.run
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
  end
end
