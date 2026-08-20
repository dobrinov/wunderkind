namespace :topics do
  desc "Load the topic tree and prerequisite graph from db/seeds/topics.yml"
  task import: :environment do
    topics = ProblemSeeds.import_topics(Rails.root.join(ProblemSeeds::TOPICS_FILE))

    puts "Topics: #{topics.size} (#{TopicPrerequisite.count} prerequisite edges)"
  end
end
