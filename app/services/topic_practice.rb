# A session of one topic, chosen by the student — „Тренирай тема". Every
# exam-age child in the family field test asked for it in their own words
# („show me what I'm bad at and drill it"), and the only way to drill anything
# was to re-ask old mistakes.
#
# Built like CompetitionPractice: fresh problems from Dispatcher, aimed at the
# student's rating *in that topic* (Dispatcher.rating_for), at most
# SessionComposer::MAX_PER_SHAPE of one template, short rather than padded off
# the topic. Measured like any practice, because these are new problems and an
# answer is evidence; the topic is named, so a topic school has not reached for
# this child is still given (`allow` in Dispatcher.available_pool).
#
# `weakest` is what „Слаби места" shows: of the topics the student has really
# played and that have problems near them, the ones rated furthest below the
# student's own rating.
module TopicPractice
  QUESTION_COUNT = 10
  OVERDRAW = 3
  MIN_GAMES = 3
  WEAK_COUNT = 3

  NothingToPractise = Class.new(StandardError)

  module_function

  def execute(user:, topic:, question_count: QUESTION_COUNT)
    candidates = Dispatcher.pick(user, count: question_count * OVERDRAW, topic_ids: [ topic.id ])
    seen = Hash.new(0)
    questions = candidates.select { |question| (seen[ProblemSeeds.shape_of(question.body_text.to_s)] += 1) <= SessionComposer::MAX_PER_SHAPE }
                          .first(question_count)
    raise NothingToPractise if questions.empty?

    assignment = Assignment.build(user: user, kind: :practice)
    ActiveRecord::Base.transaction do
      questions.shuffle.each_with_index do |question, index|
        assignment.assignment_questions.build(question: question, position: index + 1)
      end
      assignment.save!
    end
    assignment
  end

  # The offer, as PracticeFocuses shows it to a parent: leaf topics with
  # enough problems near the student, grouped by area.
  def offer(user)
    PracticeFocuses.offer(user)
  end

  def weakest(user, offer: offer(user))
    offer.flat_map(&:entries)
         .select { |entry| entry.skill && entry.skill.games_count >= MIN_GAMES && entry.skill.rating < user.elo }
         .sort_by { |entry| entry.skill.rating - user.elo }
         .first(WEAK_COUNT)
  end
end
