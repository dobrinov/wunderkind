module Elo
  extend self

  # Constants for rating system
  BASE_K_FACTOR = 32
  UPSET_MULTIPLIER = 2.5
  EXPECTED_THRESHOLD = 0.25
  MIN_RATING_CHANGE = 1
  MAX_K_FACTOR = 80

  # A skip ("I haven't been taught this") is not a loss: the student never
  # played, so only the question moves. Its K is a fraction of the base one and
  # none of the upset multipliers apply, so a run of honest skips nudges a
  # misplaced question instead of running away with its rating.
  SKIP_K_FACTOR = 8

  # How much a question's rating rises when a student declares they have never
  # been taught it. This is an ordinary Elo loss for the question with the small
  # K above, which makes the size self-scaling: a question already rated far
  # above the student tells us almost nothing when skipped (+1), while one rated
  # at or below them is plainly mistagged or misplaced in the curriculum and
  # moves the most.
  def skip_adjustment(user_rating:, question_rating:)
    player_expected = 1.0 / (1 + 10**((question_rating - user_rating) / 400.0))

    [ (SKIP_K_FACTOR * player_expected).round, MIN_RATING_CHANGE ].max
  end

  def calculate_ratings(player_rating, task_rating, player_won:, player_games:, task_games:)
    player_expected = 1.0 / (1 + 10**((task_rating - player_rating) / 400.0))
    task_expected = 1.0 - player_expected

    player_actual = player_won ? 1.0 : 0.0
    task_actual = player_won ? 0.0 : 1.0

    # Calculate K-factors with different rules for upsets
    player_k = calculate_k_factor(
      rating: player_rating,
      games_played: player_games,
      expected_score: player_expected,
      actual_score: player_actual
    )

    task_k = calculate_k_factor(
      rating: task_rating,
      games_played: task_games,
      expected_score: task_expected,
      actual_score: task_actual
    )

    # The change is K × (actual − expected), nothing more: an upset is paid for
    # exactly once, through the boosted K above, so MAX_K_FACTOR really is the
    # ceiling on a single move. A second multiplier used to be applied here
    # ("asymmetric scaling") whose upset predicates were true for *every*
    # result — all wins ×1.5, all losses ×2, after the cap — which quietly
    # deflated ratings and let one provisional upset move ~160 points. A change
    # may round to zero when the result was foregone (a strong student clearing
    # a trivial question tells us nothing), and that zero is deliberate:
    # flooring it would let easy questions be farmed for rating.
    player_change = (player_k * (player_actual - player_expected)).round
    task_change = (task_k * (task_actual - task_expected)).round

    new_player_rating = [ player_rating + player_change, 0 ].max
    new_task_rating = [ task_rating + task_change, 0 ].max

    [ new_player_rating, new_task_rating ]
  end

  private

  # Dynamic K-factor calculation with upset bonuses
  def calculate_k_factor(rating:, games_played:, expected_score:, actual_score:)
    # Base K-factor decreases with more games (rating becomes more stable)
    base_k = BASE_K_FACTOR
    if games_played < 10
      base_k = 50
    elsif games_played < 30
      base_k = 40
    elsif games_played > 100
      base_k = 20
    end

    # Boost K-factor for upsets (when low probability events occur)
    is_upset = (expected_score < EXPECTED_THRESHOLD && actual_score == 1.0) ||
               (expected_score > (1.0 - EXPECTED_THRESHOLD) && actual_score == 0.0)

    k_factor = is_upset ? (base_k * UPSET_MULTIPLIER).round : base_k

    # Cap the maximum K-factor
    [ k_factor, MAX_K_FACTOR ].min
  end
end
