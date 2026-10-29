# The numbers the admin's topic pages read, for every topic at once.
#
# Grouped queries over the whole tree rather than a count per row: the tree is
# fifty-odd rows, and each row wants a published count, the Elo range its
# problems span and how often students said „не съм го учил" to them. Areas
# are counted on their own (DISTINCT question) rather than summed from their
# topics, because a question can sit in two topics of one area and would be
# counted twice.
class TopicStats
  Row = Struct.new(:published, :min_elo, :max_elo, :answers, :skipped, keyword_init: true) do
    def skip_share = answers.positive? ? skipped.fdiv(answers) : nil
  end

  EMPTY = Row.new(published: 0, min_elo: nil, max_elo: nil, answers: 0, skipped: 0).freeze

  # How many students answer „не съм го учил" before a share is worth a colour:
  # a quarter of all answers were skips in production, concentrated in topics
  # school had not reached (see Dispatcher.held_topic_ids), so a third marks a
  # topic that is being met too early or is tagged wrongly.
  HIGH_SKIP_SHARE = 0.3

  # The area a topic belongs to — itself, for an area.
  AREA = "COALESCE(t.parent_id, t.id)".freeze

  def for(topic) = (topic.area? ? areas : topics).fetch(topic.id, EMPTY)

  # Questions attached to an area itself rather than to one of its topics. The
  # importer only ever attaches leaves, but the question editor lists every
  # topic, so it can happen and the tree says so.
  def direct(area) = topics.fetch(area.id, EMPTY)

  # The scale every range bar is drawn on: the easiest and the hardest
  # published problem in the bank.
  def bank_range
    @bank_range ||= begin
      low, high = Question.published.pick(Arel.sql("MIN(elo)"), Arel.sql("MAX(elo)"))
      low ? [ low, [ high, low + 1 ].max ] : [ 0, 1 ]
    end
  end

  # Published problems inside each grade's Elo window, per topic — the
  # number that decides whether a grade page lists the topic
  # (Curriculum.topics_for). One query with a column per grade.
  def by_grade
    @by_grade ||= begin
      columns = Curriculum.grades.map do |grade|
        Arel.sql(ActiveRecord::Base.sanitize_sql_array(
          [ "COUNT(*) FILTER (WHERE questions.elo >= ? AND questions.elo < ?)", grade.floor, grade.ceiling ]
        ))
      end

      published_scope.group("qt.topic_id").pluck(Arel.sql("qt.topic_id"), *columns).to_h do |topic_id, *counts|
        [ topic_id, Curriculum.grades.map(&:number).zip(counts).to_h ]
      end
    end
  end

  private

  def topics
    @topics ||= merge(published_by("qt.topic_id"), answers_by("qt.topic_id"))
  end

  def areas
    @areas ||= merge(published_by(AREA), answers_by(AREA))
  end

  def published_scope
    Question.published
            .joins("JOIN questions_topics qt ON qt.question_id = questions.id")
            .joins("JOIN topics t ON t.id = qt.topic_id")
  end

  def published_by(key)
    published_scope.group(Arel.sql(key))
                   .pluck(Arel.sql(key), Arel.sql("COUNT(DISTINCT questions.id)"),
                          Arel.sql("MIN(questions.elo)"), Arel.sql("MAX(questions.elo)"))
                   .to_h { |id, count, low, high| [ id, { published: count, min_elo: low, max_elo: high } ] }
  end

  # Every answer ever given, retired questions included: a skip is evidence
  # about the topic, not about the one problem.
  def answers_by(key)
    UserAnswer.joins("JOIN assignment_questions aq ON aq.id = user_answers.assignment_question_id")
              .joins("JOIN questions_topics qt ON qt.question_id = aq.question_id")
              .joins("JOIN topics t ON t.id = qt.topic_id")
              .group(Arel.sql(key))
              .pluck(Arel.sql(key), Arel.sql("COUNT(DISTINCT user_answers.id)"),
                     Arel.sql("COUNT(DISTINCT user_answers.id) FILTER (WHERE user_answers.skipped)"))
              .to_h { |id, answers, skipped| [ id, { answers: answers, skipped: skipped } ] }
  end

  def merge(published, answers)
    (published.keys | answers.keys).to_h do |id|
      [ id, Row.new(**EMPTY.to_h, **published.fetch(id, {}), **answers.fetch(id, {})) ]
    end
  end
end
