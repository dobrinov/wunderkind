# Loads the curated problem set from db/seeds/problems.yml, which is the
# source of truth for the question bank. The file is data, not code: problems
# are edited there (or in the admin UI and exported back), not generated.
module ProblemSeeds
  # Cap on near-identical problems per shape. Two problems with the same
  # wording and different numbers are the same exercise to a student, so a
  # handful of each is plenty.
  MAX_PER_SHAPE = 5

  module_function

  # A problem's "shape": its text with every number collapsed, so
  # parameter-only variants group together.
  def shape_of(text)
    text.gsub(/\d+([.,]\d+)?/, "#").gsub(/\s+/, " ").strip
  end

  def build_topics(tree, prerequisites)
    topics = {}

    tree.each_with_index do |(root_name, children), root_index|
      root = Topic.find_or_create_by!(name: root_name) { |topic| topic.position = root_index }
      topics[root_name] = root

      children.each_with_index do |child_name, child_index|
        child = Topic.find_or_initialize_by(name: child_name)
        child.parent = root
        child.position = child_index
        child.save!
        topics[child_name] = child
      end
    end

    prerequisites.each do |topic_name, prerequisite_names|
      next unless topics[topic_name]

      prerequisite_names.each do |prerequisite_name|
        next unless topics[prerequisite_name]

        TopicPrerequisite.find_or_create_by!(topic: topics[topic_name], prerequisite: topics[prerequisite_name])
      end
    end

    topics
  end

  def import(problems, topics)
    stats = { created: 0, updated: 0, skipped: 0 }
    existing = Question.where.not(body_text: nil).pluck(:body_text, :id).to_h

    problems.each_slice(500) do |batch|
      ActiveRecord::Base.transaction do
        batch.each do |problem|
          topic = topics[problem["topic"]]
          raise "Unknown topic #{problem['topic'].inspect}" if topic.nil?

          question = existing[problem["text"]] ? Question.find(existing[problem["text"]]) : Question.new
          was_new = question.new_record?

          # Nested attributes without ids append, so re-importing a
          # multiple-choice question would stack another copy of every option.
          # Options are owned by the seed file: clear them and rebuild.
          question.possible_answers.destroy_all unless was_new

          question.assign_attributes(
            body: RichContent.text_to_doc(problem["text"]),
            explanation: problem["explanation"].presence,
            status: :published,
            elo: problem["elo"],
            grade_min: problem["grade_min"],
            grade_max: problem["grade_max"],
            **answer_attributes(problem)
          )
          question.topics = [ topic ]

          if question.save
            was_new ? stats[:created] += 1 : stats[:updated] += 1
          else
            stats[:skipped] += 1
            warn "Skipped #{problem['text'].inspect}: #{question.errors.full_messages.join(', ')}"
          end
        end
      end
    end

    stats
  end

  def answer_attributes(problem)
    if problem["widget"]
      { answer_type: :interactive, grading: problem["widget"] }
    elsif problem["options"]
      {
        answer_type: :multiple_choice,
        grading: {},
        possible_answers_attributes: problem["options"].each_with_index.map do |option, index|
          { value: option, correct: option.to_s == problem["answer"].to_s, position: index + 1 }
        end
      }
    else
      { answer_type: :exact_value, grading: { "expected" => problem["answer"].to_s } }
    end
  end

  # Writes the current bank back out, thinned to max_per_shape. Keeps the
  # difficulty spread within each shape rather than the first few generated.
  def export(path, max_per_shape: MAX_PER_SHAPE)
    grouped = Question.published.includes(:topics, :possible_answers).group_by { |q| shape_of(q.body_text) }

    kept = grouped.flat_map do |_shape, group|
      next group if group.size <= max_per_shape

      sorted = group.sort_by { |question| [ question.elo, question.body_text ] }
      step = sorted.size.to_f / max_per_shape
      (0...max_per_shape).map { |index| sorted[(index * step).floor] }
    end

    payload = {
      "topics" => Topic.roots.ordered.to_h { |root| [ root.name, root.children.ordered.map(&:name) ] },
      "prerequisites" => TopicPrerequisite.includes(:topic, :prerequisite).
        group_by { |edge| edge.topic.name }.
        transform_values { |edges| edges.map { |edge| edge.prerequisite.name }.sort }.
        sort.to_h,
      "problems" => kept.sort_by { |q| [ q.elo, q.body_text ] }.map { |question| serialize(question) }
    }

    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, payload.to_yaml(line_width: -1))
    kept.size
  end

  def serialize(question)
    row = {
      "text" => question.body_text,
      "topic" => question.topics.first&.name,
      "elo" => question.elo,
      "grade_min" => question.grade_min,
      "grade_max" => question.grade_max
    }
    row["explanation"] = question.explanation if question.explanation.present?

    case question.answer_type
    when "multiple_choice"
      row["answer"] = question.correct_possible_answers.map(&:value).join(", ")
      row["options"] = question.possible_answers.sort_by(&:position).map(&:value)
    when "interactive"
      row["answer"] = Grading.correct_answer_display(question)
      row["widget"] = question.grading
    else
      row["answer"] = question.grading["expected"]
    end

    row
  end
end
