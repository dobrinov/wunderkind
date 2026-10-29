# Folding one topic into another — „Слей с друга тема…" on the admin's topic
# editor, for two topics that turned out to be one („Обиколка" and
# „Периметър"). Everything that points at the merged topic is moved to the one
# it is merged into, then the merged topic is deleted and its public address
# becomes an old address of the survivor, so /matematika/tema/<old> 301s.
#
# Every table with a topic_id is handled here (db/structure.sql: questions_topics,
# skills, topic_prerequisites both ways, practice_focus_topics, challenge_topics);
# a new one has to be added, or the delete at the end fails on its foreign key,
# which is the safe way round.
module TopicMerge
  Result = Struct.new(:topic, :error, :detail, keyword_init: true) do
    def ok? = error.nil?
  end

  # Join tables whose rows simply move, unless the target already has the
  # same row (a question in both topics, a focus naming both): then the
  # duplicate is dropped. The second column is what makes a row the same row.
  # Written out per table rather than built from the table names, so no SQL
  # here is assembled from strings.
  LINKS = {
    questions_topics: <<~SQL.squish,
      UPDATE questions_topics SET topic_id = $1 WHERE topic_id = $2 AND NOT EXISTS
        (SELECT 1 FROM questions_topics kept WHERE kept.topic_id = $1 AND kept.question_id = questions_topics.question_id)
    SQL
    practice_focus_topics: <<~SQL.squish,
      UPDATE practice_focus_topics SET topic_id = $1 WHERE topic_id = $2 AND NOT EXISTS
        (SELECT 1 FROM practice_focus_topics kept WHERE kept.topic_id = $1 AND kept.practice_focus_id = practice_focus_topics.practice_focus_id)
    SQL
    challenge_topics: <<~SQL.squish
      UPDATE challenge_topics SET topic_id = $1 WHERE topic_id = $2 AND NOT EXISTS
        (SELECT 1 FROM challenge_topics kept WHERE kept.topic_id = $1 AND kept.challenge_id = challenge_topics.challenge_id)
    SQL
  }.freeze

  # What the move leaves behind is a duplicate of a row the target has.
  LEFTOVERS = {
    questions_topics: "DELETE FROM questions_topics WHERE topic_id = $1",
    practice_focus_topics: "DELETE FROM practice_focus_topics WHERE topic_id = $1",
    challenge_topics: "DELETE FROM challenge_topics WHERE topic_id = $1"
  }.freeze

  module_function

  def call(source, into:)
    target = into
    return Result.new(error: :same) if target.nil? || target.id == source.id
    return Result.new(error: :not_a_topic) if source.area? || target.area?

    edges = merged_edges(source, target)
    cycle = cycle_in(edges)
    return Result.new(error: :cycle, detail: Topic.where(id: cycle).pluck(:name).join(" → ")) if cycle

    Topic.transaction do
      LINKS.each_key { |table| move_links(table, source, target) }
      move_skills(source, target)
      move_focus_ratings(source, target)
      rewrite_prerequisites(source, target, edges)

      slugs = (target.previous_slugs + [ source.slug ] + source.previous_slugs).uniq - [ target.slug ]
      source.reload.destroy!
      target.update_columns(previous_slugs: slugs, updated_at: Time.current)
    end

    Result.new(topic: target)
  end

  # The prerequisite graph with `source` renamed to `target`: what the merged
  # topic required, the target now requires; what required the merged topic
  # now requires the target. Self-loops (the two required each other, or one
  # required the other) and duplicates fall away.
  def merged_edges(source, target)
    TopicPrerequisite.pluck(:topic_id, :prerequisite_id)
                     .map { |pair| pair.map { |id| id == source.id ? target.id : id } }
                     .reject { |topic_id, prerequisite_id| topic_id == prerequisite_id }
                     .uniq
  end

  # Merging can close a loop that neither topic had on its own (the merged
  # topic required A, and A requires the target), and a loop is a pair of
  # topics the frontier never opens. Returns the ids on one, or nil.
  def cycle_in(edges)
    requires = edges.group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
    state = {}

    visit = lambda do |id, path|
      return path.drop(path.index(id)) + [ id ] if state[id] == :open
      return nil if state[id] == :done

      state[id] = :open
      found = requires.fetch(id, []).lazy.filter_map { |next_id| visit.call(next_id, path + [ id ]) }.first
      state[id] = :done
      found
    end

    requires.keys.lazy.filter_map { |id| visit.call(id, []) }.first
  end

  def move_links(table, source, target)
    connection.exec_update(LINKS.fetch(table), "TopicMerge", [ target.id, source.id ])
    connection.exec_delete(LEFTOVERS.fetch(table), "TopicMerge", [ source.id ])
  end

  # A student with a rating in both topics keeps the one with more games
  # behind it and loses the other. Not an average: each rating is its own
  # calibration against its own questions, and the mean of a settled rating
  # and a three-answer guess is worse than the settled one. Not a sum of
  # games either: the kept row's review schedule and mastery belong to the
  # games that produced it. A tie keeps the target's row, which is the topic
  # the student will meet from now on.
  def move_skills(source, target)
    connection.exec_delete(<<~SQL.squish, "TopicMerge", [ target.id, source.id ])
      DELETE FROM skills kept USING skills merged
      WHERE kept.topic_id = $1 AND merged.topic_id = $2
        AND kept.user_id = merged.user_id AND merged.games_count > kept.games_count
    SQL
    connection.exec_delete(<<~SQL.squish, "TopicMerge", [ source.id, target.id ])
      DELETE FROM skills merged USING skills kept
      WHERE merged.topic_id = $1 AND kept.topic_id = $2 AND kept.user_id = merged.user_id
    SQL
    Skill.where(topic_id: source.id).update_all(topic_id: target.id, updated_at: Time.current)
  end

  # A focus records each topic's rating when it was set, keyed by topic id;
  # the merged topic's starting point carries over unless the focus already
  # named the target, whose own starting point stands.
  def move_focus_ratings(source, target)
    PracticeFocus.where("starting_ratings ->> ? IS NOT NULL", source.id.to_s).find_each do |focus|
      ratings = focus.starting_ratings.dup
      moved = ratings.delete(source.id.to_s)
      ratings[target.id.to_s] ||= moved
      focus.update_columns(starting_ratings: ratings)
    end
  end

  def rewrite_prerequisites(source, target, edges)
    involved = [ source.id, target.id ]
    TopicPrerequisite.where(topic_id: involved).or(TopicPrerequisite.where(prerequisite_id: involved)).delete_all
    rows = edges.select { |pair| pair.intersect?(involved) }
                .map { |topic_id, prerequisite_id| { topic_id: topic_id, prerequisite_id: prerequisite_id } }
    TopicPrerequisite.insert_all(rows) if rows.any?
  end

  def connection = ActiveRecord::Base.connection
end
