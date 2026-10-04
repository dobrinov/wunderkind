# Which categories a student can actually duel in.
#
# A category is one of the thirteen root topics — „Геометрия", „Дроби и
# проценти" — and not one of the forty-two leaves under them, because the list
# is read by a nine-year-old choosing what to play and „Събиране на дроби с
# еднакви знаменатели" is not a choice, it is a syllabus entry.
#
# The reason this is a service and not `Topic.roots` is that **a category is
# not offerable to everyone**. The bank is not square: Тригонометрия has
# nothing at all below 1800 and Аритметика nothing above 2200, so a nine-year-
# old offered „Тригонометрия" either gets an error or — worse, because
# Dispatcher widens until it finds something — gets five problems a thousand
# points over their head and loses a duel to the question bank rather than to
# their opponent. Offering a category with nothing behind it for *this* player
# is the same mistake as a grade page promising a topic with no problems in it;
# see Curriculum::MINIMUM_PER_TOPIC.
module DuelCategories
  # How far either side of the target a problem still counts as „near enough to
  # play". Wider than Dispatcher::BAND, because a duel is pitched at the
  # midpoint of two players and should not vanish over a fifty-point step;
  # narrower than the widening steps, which exist to stop a session failing and
  # will happily reach across the whole bank.
  REACH = 300

  # Problems a category needs near the player before it is worth offering. One
  # match's worth is too few: the five would be the same five every time.
  MINIMUM = Challenge::QUESTION_COUNT * 3

  module_function

  # The categories this student can be offered, each with the leaf topics it
  # stands for. Ordered as the topic tree is, so the list does not reshuffle
  # itself between visits.
  def for(user)
    target = Dispatcher.target_rating(user.elo)

    # Grouped on the category itself rather than on the topic: the tree is two
    # deep, so a leaf's parent *is* its category and a root tagged directly is
    # its own. Distinct question ids, because a problem tagged with two leaves
    # under one root is one problem and would otherwise be counted twice into
    # the threshold that decides whether the category is worth offering.
    available = Question.published.
      joins(:topics).
      where(elo: (target - REACH)..(target + REACH)).
      group(Arel.sql("COALESCE(topics.parent_id, topics.id)")).
      count("DISTINCT questions.id")

    Topic.roots.ordered.select { |root| available[root.id].to_i >= MINIMUM }
  end

  # The leaf topics a set of chosen categories stands for, plus the categories
  # themselves — a question is tagged with its leaf, but a handful are tagged
  # with the root directly.
  def topic_ids_for(categories)
    ids = Array(categories).map { |category| category.respond_to?(:id) ? category.id : category.to_i }
    return [] if ids.empty?

    ids | Topic.where(parent_id: ids).pluck(:id)
  end

  # What a student actually asked for, out of whatever arrived in the params.
  # Anything that is not a category they can be offered is dropped rather than
  # refused: a stale form is not worth an error page, and the result of
  # dropping everything is „any category", which is a duel.
  def selected(user, ids)
    offered = self.for(user).map(&:id)
    Array(ids).map(&:to_i).uniq & offered
  end
end
