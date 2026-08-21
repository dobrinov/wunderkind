# Moves the question bank in and out of YAML. The topic tree ships with the app
# (db/seeds/topics.yml); problems do not — the bank starts empty and is filled
# from the admin UI or by importing a problem file authored outside the app.
module ProblemSeeds
  # Cap on near-identical problems per shape. Two problems with the same
  # wording and different numbers are the same exercise to a student, so a
  # handful of each is plenty.
  MAX_PER_SHAPE = 5

  TOPICS_FILE = "db/seeds/topics.yml"
  PROBLEMS_FILE = "db/seeds/problems.yml"

  module_function

  # Builds the topic tree and prerequisite graph from a topics file.
  def import_topics(path)
    data = YAML.safe_load_file(path)

    build_topics(data.fetch("topics"), data.fetch("prerequisites"))
  end

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
            status: problem.fetch("status", "published"),
            elo: problem["elo"],
            **answer_attributes(problem)
          )
          question.topics = [ topic ]
          attach_image(question, problem["image"], problem["image_filename"]) if problem["image"].present?
          assign_hint(question, problem["hints"])

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

  # A hint ladder shipped with the problem: rungs revealed one at a time, each
  # more specific than the last, none of them the answer.
  #
  # These arrive reviewed. The problems, answers and worked explanations in the
  # same file already go live on import without anyone approving them, so
  # holding their hints back would only mean students never see one — the
  # `reviewed_at` gate exists for hints typed into the admin form, where a human
  # is mid-edit. A file with no `hints` key leaves an existing hint alone rather
  # than deleting it, so re-importing a corpus that predates the key is safe;
  # `hints: []` is how a file says "remove them".
  def assign_hint(question, rungs)
    return if rungs.nil?

    ladder = Array(rungs).map { |rung| rung.to_s.strip }.reject(&:empty?)
    if ladder.empty?
      question.hint&.destroy
      question.reload_hint if question.persisted?
      return
    end

    hint = question.hint || question.build_hint
    hint.ladder = ladder
    hint.reviewed_at ||= Time.current
    hint.save! if question.persisted?
  end

  # A question carries at most one image, on the polymorphic attachable rather
  # than inside the body (RichContent has no image node). Seeds name a file
  # relative to Rails.root; re-importing the same file is a no-op.
  def attach_image(question, path, filename = nil)
    file = Rails.root.join(path)
    raise "Image not found: #{file}" unless File.exist?(file)

    # Corpus crops are all named problem.png, so callers can supply a
    # meaningful filename; storage keys off the blob id either way.
    name = filename.presence || File.basename(path)
    image = question.image || QuestionImage.new
    if image.file.attached? && image.file.filename.to_s == name
      question.attachable = image
      return
    end

    image.file.attach(io: File.open(file), filename: name,
                      content_type: Marcel::MimeType.for(file))
    image.save!
    question.attachable = image
  end

  def answer_attributes(problem)
    if problem["widget"]
      { answer_type: :interactive, grading: problem["widget"] }
    elsif problem["rubric"]
      # Free text is graded by the assigner, not the app: the rubric is what
      # they mark against. These never enter self-serve practice.
      { answer_type: :free_text, grading: { "rubric" => problem["rubric"] } }
    elsif problem["options"]
      {
        answer_type: :multiple_choice,
        grading: {},
        possible_answers_attributes: problem["options"].each_with_index.map do |option, index|
          { value: option, correct: option.to_s == problem["answer"].to_s, position: index + 1 }
        end
      }
    else
      # A tolerance is for answers that are rounded rather than exact — a length
      # computed with pi to two decimals, say. Without one the grader demands
      # the digits the author happened to write.
      grading = { "expected" => problem["answer"].to_s }
      grading["tolerance"] = problem["tolerance"] if problem["tolerance"].present?
      { answer_type: :exact_value, grading: grading }
    end
  end

  # Writes the current bank back out, thinned to max_per_shape. Keeps the
  # difficulty spread within each shape rather than the first few authored.
  # Topics go to their own file so the tree survives an empty question bank.
  def export(problems_path:, topics_path:, max_per_shape: MAX_PER_SHAPE)
    grouped = Question.published.includes(:topics, :possible_answers, :hint).group_by { |q| shape_of(q.body_text) }

    kept = grouped.flat_map do |_shape, group|
      next group if group.size <= max_per_shape

      sorted = group.sort_by { |question| [ question.elo, question.body_text ] }
      step = sorted.size.to_f / max_per_shape
      (0...max_per_shape).map { |index| sorted[(index * step).floor] }
    end

    write_yaml(topics_path, {
      "topics" => Topic.roots.ordered.to_h { |root| [ root.name, root.children.ordered.map(&:name) ] },
      "prerequisites" => TopicPrerequisite.includes(:topic, :prerequisite).
        group_by { |edge| edge.topic.name }.
        transform_values { |edges| edges.map { |edge| edge.prerequisite.name }.sort }.
        sort.to_h
    })

    write_yaml(problems_path, {
      "problems" => kept.sort_by { |q| [ q.elo, q.body_text ] }.map { |question| serialize(question) }
    })

    kept.size
  end

  def write_yaml(path, payload)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, payload.to_yaml(line_width: -1))
  end

  def serialize(question)
    row = {
      "text" => question.body_text,
      "topic" => question.topics.first&.name,
      "elo" => question.elo
    }
    row["explanation"] = question.explanation if question.explanation.present?
    row["hints"] = question.hint.ladder if question.hint&.ladder.present?

    case question.answer_type
    when "multiple_choice"
      row["answer"] = question.correct_possible_answers.map(&:value).join(", ")
      row["options"] = question.possible_answers.sort_by(&:position).map(&:value)
    when "interactive"
      row["answer"] = Grading.correct_answer_display(question)
      row["widget"] = question.grading
    when "free_text"
      row["rubric"] = question.grading["rubric"]
    else
      row["answer"] = question.grading["expected"]
      row["tolerance"] = question.grading["tolerance"] if question.grading["tolerance"].present?
    end

    row
  end
end
