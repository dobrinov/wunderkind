require "rails_helper"

# The curated problem set in db/seeds/problems.yml is the product's content, so
# it is validated like code: no template may dominate, ratings must be
# grade-appropriate, and every problem must be answerable.
describe ProblemSeeds do
  let(:data) { YAML.safe_load_file(Rails.root.join("db/seeds/problems.yml")) }
  let(:problems) { data.fetch("problems") }
  let(:topic_names) { data.fetch("topics").values.flatten }

  it "carries a usable number of problems" do
    problems.size.should be >= 1000
  end

  it "keeps near-identical problems rare" do
    shapes = problems.group_by { |problem| ProblemSeeds.shape_of(problem["text"]) }

    shapes.values.map(&:size).max.should be <= ProblemSeeds::MAX_PER_SHAPE
    shapes.size.should be >= 250
  end

  it "has no duplicate problem statements" do
    texts = problems.map { |problem| problem["text"] }

    texts.uniq.size.should eq(texts.size)
  end

  it "gives every problem a statement, an answer, a known topic, and a rating" do
    problems.each do |problem|
      problem["text"].to_s.should_not be_empty
      problem["answer"].to_s.should_not be_empty
      topic_names.should include(problem["topic"])
      problem["elo"].should be_between(600, 1900)
    end
  end

  it "keeps ratings inside the band implied by the grade" do
    problems.each do |problem|
      grade = problem["grade_min"]
      grade.should be_between(1, 7)
      # Grade 1 starts at 700 and each grade adds 130; a problem should not sit
      # more than one grade's worth away from its own band.
      floor = User.rating_for_grade(grade) - 200
      ceiling = User.rating_for_grade(grade) + 340
      problem["elo"].should be_between(floor, ceiling)
    end
  end

  it "covers grades 1 to 7" do
    problems.map { |problem| problem["grade_min"] }.uniq.sort.should eq((1..7).to_a)
  end

  it "gives the youngest grades enough distinct shapes for a varied session" do
    by_grade = problems.group_by { |problem| problem["grade_min"] }

    (1..3).each do |grade|
      by_grade[grade].map { |problem| ProblemSeeds.shape_of(problem["text"]) }.uniq.size.should be >= 15
    end
  end

  it "configures every multiple-choice problem with exactly one correct option" do
    problems.select { |problem| problem["options"] }.each do |problem|
      problem["options"].count { |option| option.to_s == problem["answer"].to_s }.should eq(1)
    end
  end

  it "configures every interactive problem for a registered widget" do
    problems.select { |problem| problem["widget"] }.each do |problem|
      Widgets.keys.should include(problem["widget"]["widget"])
      problem["widget"]["solution"].should be_present
    end
  end

  describe "importing" do
    it "loads problems as published, gradable questions" do
      topics = ProblemSeeds.build_topics(data.fetch("topics"), data.fetch("prerequisites"))
      sample = problems.first(30)

      stats = ProblemSeeds.import(sample, topics)

      stats[:skipped].should eq(0)
      stats[:created].should eq(30)

      Question.published.limit(30).each do |question|
        raw = case question.answer_type
        when "exact_value" then { value: question.grading["expected"] }
        when "multiple_choice" then { selected_ids: question.correct_possible_answers.map(&:id) }
        when "interactive" then { state: question.grading["solution"].to_json }
        end
        next if raw.nil?

        Grading.grade(question: question, raw: raw).correct.should be(true)
      end
    end

    it "is idempotent" do
      topics = ProblemSeeds.build_topics(data.fetch("topics"), data.fetch("prerequisites"))
      sample = problems.first(10)

      ProblemSeeds.import(sample, topics)
      second = ProblemSeeds.import(sample, topics)

      second[:created].should eq(0)
      second[:updated].should eq(10)
      Question.count.should eq(10)
    end
  end
end
