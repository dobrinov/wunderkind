# Shared machinery for the problem generators.
#
# Elo calibration: a question's rating is derived from the grade it targets and
# its difficulty tier, so the rating scale and the curriculum stay in sync.
#
#   elo = 700 + (grade - 1) * 130 + tier_offset
#
# Grade 1 intro sits at 640 and grade 7 competition at 2060. A student's
# starting rating is the "easy" anchor for their grade (700 for grade 1, 1480
# for grade 7), so the near-Elo search can only reach material at or around
# their own level — a first-grader is never served a seventh-grade problem.
module ProblemGenerators
  GRADE_STEP = 130
  GRADE_ONE_ANCHOR = 700

  TIER_OFFSETS = {
    intro: -60,        # scaffolded on-ramp: tiny numbers, one step
    easy: 0,           # routine for the grade
    medium: 90,        # needs a little thought
    hard: 180,         # multi-step, strong students
    competition: 280   # competition-style reasoning
  }.freeze

  TIERS = TIER_OFFSETS.keys.freeze

  module_function

  def elo_for(grade:, tier:)
    GRADE_ONE_ANCHOR + (grade - 1) * GRADE_STEP + TIER_OFFSETS.fetch(tier)
  end

  def starting_elo_for_grade(grade)
    elo_for(grade: grade.clamp(1, 7), tier: :easy)
  end

  # Every generator yields hashes through this, so all problems get the same
  # shape and the importer stays dumb.
  def problem(text:, answer:, topic:, grade:, tier:, explanation: nil, options: nil, widget: nil)
    {
      text: text,
      answer: answer.to_s,
      topic: topic,
      grade: grade,
      tier: tier,
      elo: elo_for(grade: grade, tier: tier),
      explanation: explanation,
      options: options,
      widget: widget
    }
  end

  # Deterministic pseudo-randomness: the same seed regenerates the same
  # database, so reruns don't churn the question set.
  def rng(salt)
    Random.new(Digest::MD5.hexdigest(salt.to_s)[0, 8].to_i(16))
  end

  def plural_bg(count, one, many)
    count == 1 ? "#{count} #{one}" : "#{count} #{many}"
  end
end
