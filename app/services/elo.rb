module Elo
  extend self

  # Constants for rating system
  BASE_K_FACTOR = 32
  UPSET_MULTIPLIER = 2.5
  EXPECTED_THRESHOLD = 0.25
  MIN_RATING_CHANGE = 1
  MAX_K_FACTOR = 80

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

    # Calculate rating changes
    player_change = (player_k * (player_actual - player_expected)).round
    task_change = (task_k * (task_actual - task_expected)).round

    # Apply minimum change rules and asymmetric scaling
    player_change = apply_asymmetric_scaling(player_change, player_expected, player_actual)
    task_change = apply_asymmetric_scaling(task_change, task_expected, task_actual)

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

  # Apply asymmetric scaling - bigger changes for upsets, smaller for expected results
  def apply_asymmetric_scaling(change, expected_score, actual_score)
    return change if change.abs < MIN_RATING_CHANGE

    is_upset_win = actual_score == 1.0 && actual_score > expected_score
    is_upset_loss = actual_score == 0.0 && actual_score < expected_score

    multiplier =
      if is_upset_win
        1.5
      elsif is_upset_loss
        2
      else
        1.0
      end

    change = (change * multiplier).round

    # Ensure minimum change for any result
    if change.abs < MIN_RATING_CHANGE
      change = change >= 0 ? MIN_RATING_CHANGE : -MIN_RATING_CHANGE
    end

    change
  end
end
