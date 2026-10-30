# What a child practises, when a parent has said: a focus on a few topics
# (PracticeFocus) until a target is reached, and then back to general practice.
#
# Everything here is computed on read, like Goals: how far the child has got is
# a question asked of their `skills` rows every time anybody looks, and the only
# thing written when the target is reached is the completion stamp. There is no
# job runner, so `refresh!` runs from the pages that show a focus — the child's
# home, the parent's child page and the family list — and is idempotent.
module PracticeFocuses
  # A topic is offered only where the bank holds this many published problems
  # within REACH of the child's level — the same bar a grade page sets before it
  # lists a topic (Curriculum::MINIMUM_PER_TOPIC), and the same reach a duel
  # category is offered within (DuelCategories::REACH). A focus must never mean
  # „problems far above you": the session does not widen past REACH, so a topic
  # with nothing near the child would leave the focus empty and the session
  # quietly general.
  MINIMUM = Curriculum::MINIMUM_PER_TOPIC
  REACH = DuelCategories::REACH

  # Points a topic's rating must rise for the „one step forward" target.
  STEP = StudentProgress::STEP

  # The bottom of RatingBand's scale, which is where „how far toward mastery"
  # is measured from on the parent's topic list: a rating at or under it has
  # not started climbing toward AnswerSubmission::MASTERY_RATING yet.
  PROGRESS_FLOOR = 800

  Entry = Struct.new(:topic, :available, :skill, keyword_init: true) do
    def stage = PracticeFocuses.stage(skill)
    def fraction = PracticeFocuses.mastery_fraction(skill)
  end
  Group = Struct.new(:root, :entries, keyword_init: true)

  TopicProgress = Struct.new(:topic, :fraction, :done, :gained, keyword_init: true) do
    def done? = done
  end

  Progress = Struct.new(:topics, keyword_init: true) do
    def complete? = topics.all?(&:done?)
    def fraction = topics.empty? ? 0.0 : topics.sum { |topic| topic.done? ? 1.0 : topic.fraction } / topics.size
    def done_count = topics.count(&:done?)
  end

  # Steps the child's card is drawn in: a row of pips rather than a percentage,
  # because a child reads „three of five" and a parent's rating arithmetic is
  # not theirs to see.
  STEPS = 5

  module_function

  # The focus in play for this child, or nil. Completes it on the way if its
  # target has been reached since anybody last looked.
  def refresh!(child)
    focus = PracticeFocus.active.where(child: child).includes(:topics).first
    return nil if focus.nil?

    if progress(focus).complete?
      focus.update!(completed_at: Time.current)
      return nil
    end

    focus
  end

  # The focus a page should show: in play, or finished and not yet replaced.
  def current(child)
    PracticeFocus.current.where(child: child).includes(:topics, :parent).order(created_at: :desc).first
  end

  # What the daily session draws from while a focus is in play: one group of
  # topic ids per focus topic not yet at its target (the topic and whatever
  # sits under it in the tree), so a focus on two topics spends the child's
  # time on the one still to go and SessionComposer can aim at the child's
  # rating in each. Empty when there is no focus, which is general practice.
  def session_topic_groups(child)
    focus = refresh!(child)
    return [] if focus.nil?

    remaining = progress(focus).topics.reject(&:done?).map { |entry| entry.topic.id }
    children = Topic.where(parent_id: remaining).pluck(:parent_id, :id).group_by(&:first)

    remaining.map { |topic_id| [ topic_id ] + children.fetch(topic_id, []).map(&:last) }
  end

  def progress(focus)
    skills = focus.child.skills.where(topic_id: focus.topics.map(&:id)).index_by(&:topic_id)

    Progress.new(topics: focus.topics.sort_by(&:name).map { |topic| topic_progress(focus, topic, skills[topic.id]) })
  end

  def topic_progress(focus, topic, skill)
    start = focus.starting_rating(topic)
    rating = skill&.rating || start

    if focus.mastery?
      done = skill&.mastered_at.present?
      TopicProgress.new(topic: topic, done: done, fraction: done ? 1.0 : mastery_fraction(skill, from: start), gained: rating - start)
    else
      gained = rating - start
      TopicProgress.new(topic: topic, done: gained >= STEP, fraction: (gained.to_f / STEP).clamp(0.0, 1.0), gained: gained)
    end
  end

  # How far a skill row is toward the app's mastery rule — both halves of it,
  # the rating and the games, and only as far as the shorter of the two: ten
  # lucky answers at a low rating are not nearly mastered, and nor is a high
  # rating reached in two.
  def mastery_fraction(skill, from: PROGRESS_FLOOR)
    return 0.0 if skill.nil? || skill.games_count.zero?
    return 1.0 if skill.mastered_at.present?

    span = AnswerSubmission::MASTERY_RATING - from
    rating = span.positive? ? ((skill.rating - from) / span.to_f).clamp(0.0, 1.0) : 1.0
    games = (skill.games_count / AnswerSubmission::MASTERY_MIN_GAMES.to_f).clamp(0.0, 1.0)
    [ rating, games ].min
  end

  # The word on the parent's topic list: where the child stands in a topic.
  def stage(skill)
    return :not_started if skill.nil? || skill.games_count.zero?
    return :mastered if skill.mastered_at.present?

    fraction = mastery_fraction(skill)
    if fraction < 0.34 then :started
    elsif fraction < 0.75 then :midway
    else :almost
    end
  end

  # An exam's preparation as a focus, for a parent who knows the exam and not
  # the topic list: of the topics on offer that the exam asks for (its
  # programme, Competitions), the child's weakest MAX_TOPICS — least of the way
  # to mastery first. Ticked in the form, never saved without the parent
  # pressing „Запази". In the family field test a mother built a 7th-grader's
  # НВО focus by hand out of ~45 unlabelled topics.
  def exam_preset(offer, exam)
    wanted = exam.topic_names.to_set
    offer.flat_map(&:entries)
         .select { |entry| wanted.include?(entry.topic.name) }
         .sort_by { |entry| [ entry.fraction, entry.topic.name ] }
         .first(PracticeFocus::MAX_TOPICS)
         .map { |entry| entry.topic.id }
  end

  # The topics a parent can choose from for this child: leaves of the topic
  # tree grouped under their root, as the duel's categories are, and only
  # those with MINIMUM problems near the child. `keep` names topics to list
  # whatever their count — the ones in the focus already in play, so a topic
  # that has since gone thin is shown with a note rather than silently dropped
  # from a focus the parent set.
  def offer(child, keep: [])
    counts = available_counts(child)
    skills = child.skills.index_by(&:topic_id)
    keep_ids = Array(keep).map(&:to_i)

    # Leaves, not roots: a skill row — and so the progress and the target — is
    # kept per leaf, which is what a question is tagged with. A root with no
    # leaves under it is its own leaf.
    leaves = Topic.where.not(id: Topic.where.not(parent_id: nil).select(:parent_id)).includes(:parent).to_a
    offered = leaves.select { |topic| counts[topic.id].to_i >= MINIMUM || keep_ids.include?(topic.id) }

    offered.group_by { |topic| topic.parent || topic }.sort_by { |root, _| [ root.position || 0, root.name ] }.map do |root, topics|
      Group.new(root: root, entries: topics.sort_by { |topic| [ topic.position || 0, topic.name ] }.map do |topic|
        Entry.new(topic: topic, available: counts[topic.id].to_i, skill: skills[topic.id])
      end)
    end
  end

  # Published problems per topic within REACH of the child's working level, in
  # one query. Aimed at the child's overall rating rather than each topic's:
  # the list is read to decide what to ask for, and the session itself aims at
  # the topic's own rating once it is chosen.
  def available_counts(child)
    target = Dispatcher.target_rating(child.elo)

    Dispatcher.practice_pool.
      joins(:topics).
      where(elo: (target - REACH)..(target + REACH)).
      group("topics.id").
      count("DISTINCT questions.id")
  end

  # The topics of a focus with too few problems near the child to carry a
  # session on their own — said in one sentence on the parent's tab, because
  # a focus whose sessions are mostly general practice is not what the parent
  # thinks they set.
  def thin_topics(focus)
    counts = available_counts(focus.child)
    focus.topics.select { |topic| counts[topic.id].to_i < MINIMUM }
  end

  # How many problems on the focus topics the child has marked „не съм го
  # учил" since the focus was set. A skip parks the topic or the problem type
  # for a few weeks (Dispatcher.available_pool), and the focus respects that —
  # the child has told us something, and serving it again would be pushing past
  # it. But it means the focus can drain into general practice for a reason the
  # parent can do something about, so the parent's tab says so.
  def skipped_count(focus)
    topic_ids = focus.topics.map(&:id)
    topic_ids |= Topic.where(parent_id: topic_ids).pluck(:id)

    UserAnswer.where(user: focus.child, skipped: true, created_at: focus.created_at..).
      joins(assignment_question: { question: :topics }).
      where(topics: { id: topic_ids }).
      distinct.
      count(:id)
  end

  # Sets a new focus, archiving whichever one was in play. Never edits one: a
  # focus is a promise in particular words, and the reward a child is working
  # toward should not change under them without the old promise being closed.
  #
  # The one thing carried over is where each topic started, for a topic that
  # stays in the focus under the same target: a parent who fixes a typo in the
  # reward has not asked the child to start the step again.
  def set!(child:, parent:, topic_ids:, target:, reward: nil)
    PracticeFocus.transaction do
      previous = PracticeFocus.active.where(child: child).lock.first
      # A finished one leaves the page too: the next focus replaces the „done"
      # card. Its reward, if still owed, stays owed (PracticeFocus#reward_owed?).
      PracticeFocus.current.where(child: child).find_each(&:archive!)

      focus = PracticeFocus.new(child: child, parent: parent, target: target, reward: reward)
      Topic.where(id: topic_ids).find_each { |topic| focus.focus_topics.build(topic: topic) }
      focus.starting_ratings = starting_ratings(child, focus.focus_topics.map(&:topic_id), previous, target)
      focus.save!
      focus
    end
  end

  # Back to general practice — which also clears away a finished focus's
  # „done" card, the parent having seen it and chosen.
  def clear!(child)
    PracticeFocus.current.where(child: child).find_each(&:archive!)
  end

  def starting_ratings(child, topic_ids, previous, target)
    ratings = child.skills.where(topic_id: topic_ids).pluck(:topic_id, :rating).to_h
    carried = previous && previous.target == target.to_s ? previous.starting_ratings : {}

    topic_ids.to_h do |topic_id|
      [ topic_id.to_s, carried[topic_id.to_s] || ratings[topic_id] || child.elo ]
    end
  end

  # How the child is told who asked: by what the children call that parent
  # („Мама", set on the family page), else the first name — the app never
  # guesses at „мама" itself. See User#name_for_children.
  def asked_by(focus)
    focus.parent.name_for_children
  end

  # Rounded rather than floored, so the first good session lights a pip — a
  # card that still reads „0 of 5" after two sessions of work tells a child
  # the work did not count. Never the last pip before the target is reached.
  def pips(progress)
    return STEPS if progress.complete?

    (progress.fraction * STEPS).round.clamp(0, STEPS - 1)
  end
end
