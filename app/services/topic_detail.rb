# Everything the admin is told about one topic: the side panel of the topic
# tree and the right-hand column of its editor. Each number is one small query
# against this topic alone, and nothing is computed until it is asked for.
class TopicDetail
  # The histogram's bucket width, in Elo points.
  BUCKET = 100

  attr_reader :topic

  def initialize(topic)
    @topic = topic
  end

  def published = status_counts.fetch("published", 0)

  # Questions by status, for „N публикувани · M чернови · K архивирани".
  def status_counts
    @status_counts ||= topic.questions.group(:status).count
  end

  def question_count = status_counts.values.sum

  # Students whose rating in the topic has passed the mastery rule
  # (AnswerSubmission stamps skills.mastered_at).
  def mastered_count
    @mastered_count ||= topic.skills.where.not(mastered_at: nil).count
  end

  # Students with a rating in the topic at all — what a merge moves.
  def skills_count
    @skills_count ||= topic.skills.count
  end

  def skip_share
    @skip_share ||= begin
      answers, skipped = UserAnswer.joins(:assignment_question)
                                   .where(assignment_questions: { question_id: topic.questions.select(:id) })
                                   .pick(Arel.sql("COUNT(*)"), Arel.sql("COUNT(*) FILTER (WHERE user_answers.skipped)"))
      answers.to_i.positive? ? skipped.fdiv(answers) : nil
    end
  end

  def prerequisites = topic.prerequisites.ordered.to_a
  def unlocks = topic.unlocks.ordered.to_a

  # The МОН grades that list this topic by name (Curriculum::TOPICS). The
  # programme is code, not data: renaming a topic takes it off these grades
  # until the code is changed too, which is why the editor shows the list.
  def grades
    @grades ||= Curriculum::TOPICS.select { |_, names| names.include?(topic.name) }.keys
  end

  # The estimated grade below which Dispatcher.held_topic_ids keeps the topic
  # back from what the app picks on its own; nil when it is never held.
  def held_below
    first = grades.min
    first - Dispatcher::GRADE_REACH if first && first > 1 + Dispatcher::GRADE_REACH
  end

  # Published questions per Elo bucket across `range` (the bank's scale), so
  # every topic's histogram is drawn on the same axis as the tree's bars.
  def histogram(range)
    counts = topic.questions.published.group(Arel.sql("FLOOR(elo / #{BUCKET}) * #{BUCKET}")).count
                  .transform_keys(&:to_i)
    low = (range.first / BUCKET) * BUCKET
    (low..range.last).step(BUCKET).map { |floor| [ floor, counts.fetch(floor, 0) ] }
  end

  def answer_types
    @answer_types ||= topic.questions.published.group(:answer_type).count.sort_by { |_, count| -count }
  end

  def explainer = Explainers.for_topic(topic).first

  # The public page exists for every leaf; it is in the sitemap and worth
  # sending anybody to once it has enough problems behind it.
  def public_page? = topic.leaf?
  def indexed? = topic.leaf? && published >= Curriculum::MINIMUM_PER_TOPIC

  def grade_pages
    @grade_pages ||= topic.leaf? ? Curriculum.grades_for(topic) : []
  end

  def competitions
    @competitions ||= Competitions.all.select { |event| event.topic_names.include?(topic.name) }
  end

  # Running parent focuses that name the topic.
  def active_focuses
    @active_focuses ||= PracticeFocusTopic.joins(:practice_focus).merge(PracticeFocus.active).where(topic: topic).count
  end
end
