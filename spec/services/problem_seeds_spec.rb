require "rails_helper"

# The question bank starts empty; this covers the machinery that fills it and
# writes it back out, plus the topic tree that does ship with the app.
describe ProblemSeeds do
  let(:topics_file) { Rails.root.join(ProblemSeeds::TOPICS_FILE) }
  let(:topic_data) { YAML.safe_load_file(topics_file) }

  describe "the shipped topic tree" do
    it "gives every child topic a root" do
      topic_data.fetch("topics").each do |root, children|
        root.to_s.should_not be_empty
        children.should be_present
      end
    end

    it "names only known topics in the prerequisite graph" do
      known = topic_data.fetch("topics").values.flatten

      topic_data.fetch("prerequisites").each do |topic, prerequisites|
        known.should include(topic)
        prerequisites.each { |prerequisite| known.should include(prerequisite) }
      end
    end

    it "loads into the topic hierarchy" do
      topics = ProblemSeeds.import_topics(topics_file)

      topics.size.should eq(topic_data.fetch("topics").size + topic_data.fetch("topics").values.flatten.size)
      Topic.roots.count.should eq(topic_data.fetch("topics").size)
      TopicPrerequisite.count.should eq(topic_data.fetch("prerequisites").values.flatten.size)
    end

    it "is idempotent" do
      ProblemSeeds.import_topics(topics_file)
      ProblemSeeds.import_topics(topics_file)

      Topic.count.should eq(topic_data.fetch("topics").size + topic_data.fetch("topics").values.flatten.size)
      TopicPrerequisite.count.should eq(topic_data.fetch("prerequisites").values.flatten.size)
    end
  end

  describe "shape_of" do
    it "collapses numbers so parameter-only variants group together" do
      ProblemSeeds.shape_of("Колко е 12 + 7?").should eq(ProblemSeeds.shape_of("Колко е 348 + 91?"))
      ProblemSeeds.shape_of("Колко е 12 + 7?").should_not eq(ProblemSeeds.shape_of("Колко е 12 - 7?"))
    end
  end

  describe "importing" do
    let(:topics) { ProblemSeeds.import_topics(topics_file) }
    let(:problems) do
      [
        { "text" => "Колко е 12 + 7?", "topic" => "Събиране и изваждане", "answer" => "19",
          "elo" => 700, "grade_min" => 1, "grade_max" => 2, "explanation" => "12 + 7 = 19" },
        { "text" => "Кое число е просто?", "topic" => "Прости числа", "answer" => "7",
          "options" => [ "4", "7", "9" ], "elo" => 1100, "grade_min" => 4, "grade_max" => 5 },
        { "text" => "Подреди дробите.", "topic" => "Дроби", "answer" => "1/2 → 2/3",
          "widget" => {
            "widget" => "ordering",
            "params" => { "items" => [ { "id" => "b", "label" => "2/3" }, { "id" => "a", "label" => "1/2" } ] },
            "solution" => { "order" => [ "a", "b" ] }
          },
          "elo" => 1200, "grade_min" => 5, "grade_max" => 6 }
      ]
    end

    it "loads problems as published, gradable questions" do
      stats = ProblemSeeds.import(problems, topics)

      stats[:created].should eq(3)
      stats[:skipped].should eq(0)

      Question.published.count.should eq(3)
      Question.published.each do |question|
        raw = case question.answer_type
        when "exact_value" then { value: question.grading["expected"] }
        when "multiple_choice" then { selected_ids: question.correct_possible_answers.map(&:id) }
        when "interactive" then { state: question.grading["solution"].to_json }
        end

        Grading.grade(question: question, raw: raw).correct.should be(true)
      end
    end

    it "files each problem under its topic" do
      ProblemSeeds.import(problems, topics)

      Question.find_by(body_text: "Колко е 12 + 7?").topics.map(&:name).should eq([ "Събиране и изваждане" ])
    end

    it "raises on an unknown topic" do
      expect { ProblemSeeds.import([ problems.first.merge("topic" => "Астрономия") ], topics) }.
        to raise_error(/Unknown topic/)
    end

    it "is idempotent, and does not stack multiple-choice options" do
      ProblemSeeds.import(problems, topics)
      second = ProblemSeeds.import(problems, topics)

      second[:created].should eq(0)
      second[:updated].should eq(3)
      Question.count.should eq(3)
      Question.find_by(answer_type: :multiple_choice).possible_answers.count.should eq(3)
    end
  end

  # The starter bank is dev fixture data, but a broken one wastes an afternoon:
  # check it still imports and that every problem accepts its own answer.
  describe "the starter bank" do
    let(:starter) { YAML.safe_load_file(Rails.root.join("db/seeds/starter_problems.yml")).fetch("problems") }

    it "imports without skipping anything" do
      stats = ProblemSeeds.import(starter, ProblemSeeds.import_topics(topics_file))

      stats[:skipped].should eq(0)
      stats[:created].should eq(starter.size)
    end

    it "grades every problem correct when given its own answer" do
      ProblemSeeds.import(starter, ProblemSeeds.import_topics(topics_file))

      Question.published.where.not(answer_type: :free_text).each do |question|
        raw = case question.answer_type
        when "exact_value" then { value: question.grading["expected"] }
        when "multiple_choice" then { selected_ids: question.correct_possible_answers.map(&:id) }
        when "interactive" then { state: question.grading["solution"].to_json }
        end

        Grading.grade(question: question, raw: raw).correct.should be(true), question.body_text
      end
    end

    it "covers every leaf topic, all four answer types and all three widgets" do
      ProblemSeeds.import(starter, ProblemSeeds.import_topics(topics_file))

      Topic.where.not(parent_id: nil).joins(:questions).distinct.count.should eq(Topic.where.not(parent_id: nil).count)
      Question.distinct.pluck(:answer_type).sort.should eq(Question.answer_types.keys.sort)
      Question.interactive.map(&:widget_type).uniq.sort.should eq(Widgets.keys.sort)
    end

    it "covers grades 1 to 7 without letting one shape dominate" do
      starter.map { |problem| problem["grade_min"] }.uniq.sort.should eq((1..7).to_a)

      shapes = starter.group_by { |problem| ProblemSeeds.shape_of(problem["text"]) }
      shapes.values.map(&:size).max.should be <= ProblemSeeds::MAX_PER_SHAPE
    end
  end

  describe "exporting" do
    let(:dir) { Rails.root.join("tmp/problem_seeds_spec") }

    after { FileUtils.rm_rf(dir) }

    def export(max_per_shape: ProblemSeeds::MAX_PER_SHAPE)
      ProblemSeeds.export(
        problems_path: dir.join("problems.yml"),
        topics_path: dir.join("topics.yml"),
        max_per_shape: max_per_shape
      )
    end

    it "round-trips a question through the problem file" do
      topics = ProblemSeeds.import_topics(topics_file)
      ProblemSeeds.import([
        { "text" => "Колко е 12 + 7?", "topic" => "Събиране и изваждане", "answer" => "19",
          "elo" => 700, "grade_min" => 1, "grade_max" => 2 }
      ], topics)

      export

      YAML.safe_load_file(dir.join("problems.yml")).fetch("problems").should eq([
        { "text" => "Колко е 12 + 7?", "topic" => "Събиране и изваждане", "elo" => 700,
          "grade_min" => 1, "grade_max" => 2, "answer" => "19" }
      ])
    end

    it "writes the topic tree even when the bank is empty" do
      ProblemSeeds.import_topics(topics_file)

      export.should eq(0)

      written = YAML.safe_load_file(dir.join("topics.yml"))
      written.fetch("topics").should eq(YAML.safe_load_file(topics_file).fetch("topics"))
      written.fetch("prerequisites").should eq(YAML.safe_load_file(topics_file).fetch("prerequisites"))
    end

    it "thins near-identical problems down to max_per_shape" do
      topics = ProblemSeeds.import_topics(topics_file)
      ProblemSeeds.import((1..10).map do |n|
        { "text" => "Колко е #{n} + 7?", "topic" => "Събиране и изваждане", "answer" => (n + 7).to_s,
          "elo" => 700 + n, "grade_min" => 1, "grade_max" => 2 }
      end, topics)

      export(max_per_shape: 3).should eq(3)

      YAML.safe_load_file(dir.join("problems.yml")).fetch("problems").size.should eq(3)
    end
  end
end
