require 'rails_helper'

describe Elo do
  describe '#calculate_ratings' do
    context 'basic rating calculations' do
      it 'calculates correct ratings when equally rated player wins' do
        player_rating, task_rating = Elo.calculate_ratings(
          1200, 1200,
          player_won: true,
          player_games: 50,
          task_games: 50
        )

        player_rating.should > 1200
        task_rating.should < 1200
        (player_rating + task_rating).should be_within(10).of(2400)
      end

      it 'calculates correct ratings when equally rated player loses' do
        player_rating, task_rating = Elo.calculate_ratings(
          1200, 1200,
          player_won: false,
          player_games: 50,
          task_games: 50
        )

        player_rating.should < 1200
        task_rating.should > 1200
      end

      it 'gives smaller rating changes when higher rated player beats lower rated task' do
        player_rating, task_rating = Elo.calculate_ratings(
          1600, 1200,
          player_won: true,
          player_games: 50,
          task_games: 50
        )

        player_change = player_rating - 1600
        task_change = task_rating - 1200

        player_change.should be_positive
        player_change.should < 16
        task_change.should be_negative
      end

      it 'gives larger rating changes when lower rated player beats higher rated task' do
        player_rating, task_rating = Elo.calculate_ratings(
          1200, 1600,
          player_won: true,
          player_games: 50,
          task_games: 50
        )

        player_change = player_rating - 1200
        task_change = task_rating - 1600

        player_change.should > 20
        task_change.should < -20
      end
    end

    context 'K-factor calculations based on games played' do
      it 'uses higher K-factor for new players (< 10 games)' do
        player_rating, _ = Elo.calculate_ratings(
          1200, 1200,
          player_won: true,
          player_games: 5,
          task_games: 100
        )

        new_player_change = player_rating - 1200

        experienced_player_rating, _ = Elo.calculate_ratings(
          1200, 1200,
          player_won: true,
          player_games: 150,
          task_games: 100
        )

        experienced_player_change = experienced_player_rating - 1200

        new_player_change.should > experienced_player_change
      end

      it 'uses medium K-factor for developing players (10-30 games)' do
        player_rating, _ = Elo.calculate_ratings(
          1200, 1200,
          player_won: true,
          player_games: 20,
          task_games: 50
        )

        developing_player_change = player_rating - 1200

        developing_player_change.should be_between(10, 30)
      end

      it 'uses lower K-factor for experienced players (> 100 games)' do
        player_rating, _ = Elo.calculate_ratings(
          1200, 1200,
          player_won: true,
          player_games: 150,
          task_games: 50
        )

        experienced_player_change = player_rating - 1200

        experienced_player_change.should < 20
      end
    end

    context 'upset detection and bonuses' do
      it 'detects upset when low expected score player wins' do
        player_rating, task_rating = Elo.calculate_ratings(
          1000, 1800,
          player_won: true,
          player_games: 50,
          task_games: 50
        )

        player_change = player_rating - 1000
        task_change = task_rating - 1800

        player_change.should > 40
        task_change.should < -40
      end

      it 'detects upset when high expected score player loses' do
        player_rating, task_rating = Elo.calculate_ratings(
          1800, 1000,
          player_won: false,
          player_games: 50,
          task_games: 50
        )

        player_change = player_rating - 1800
        task_change = task_rating - 1000

        player_change.should < -40
        task_change.should > 40
      end

      it 'does not apply upset bonus for expected results' do
        player_rating, _ = Elo.calculate_ratings(
          1600, 1200,
          player_won: true,
          player_games: 50,
          task_games: 50
        )

        player_change = player_rating - 1600
        player_change.should < 25
      end
    end

    context 'asymmetric scaling' do
      it 'applies 1.5x multiplier for upset wins' do
        upset_win_player_rating, _ = Elo.calculate_ratings(
          1200, 1600,
          player_won: true,
          player_games: 50,
          task_games: 50
        )

        upset_win_change = upset_win_player_rating - 1200
        upset_win_change.should > 30
      end

      it 'applies 2x multiplier for upset losses' do
        upset_loss_player_rating, _ = Elo.calculate_ratings(
          1600, 1200,
          player_won: false,
          player_games: 50,
          task_games: 50
        )

        upset_loss_change = upset_loss_player_rating - 1600
        upset_loss_change.should < -30
      end
    end

    context 'minimum rating change enforcement' do
      it 'enforces minimum rating change of 1 point' do
        player_rating, task_rating = Elo.calculate_ratings(
          1500, 1502,
          player_won: true,
          player_games: 200,
          task_games: 200
        )

        player_change = player_rating - 1500
        task_change = task_rating - 1502

        player_change.abs.should >= 1
        task_change.abs.should >= 1
      end
    end

    context 'rating floors' do
      it 'prevents ratings from going below 0' do
        player_rating, task_rating = Elo.calculate_ratings(
          50, 1600,
          player_won: false,
          player_games: 10,
          task_games: 50
        )

        player_rating.should >= 0
        task_rating.should >= 0
      end

      it 'prevents both ratings from going below 0' do
        player_rating, task_rating = Elo.calculate_ratings(
          10, 5,
          player_won: false,
          player_games: 5,
          task_games: 5
        )

        player_rating.should >= 0
        task_rating.should >= 0
      end
    end

    context 'edge cases' do
      it 'handles extreme rating differences' do
        player_rating, task_rating = Elo.calculate_ratings(
          2000, 100,
          player_won: true,
          player_games: 50,
          task_games: 50
        )

        player_rating.should be_within(5).of(2000)
        task_rating.should >= 0
      end

      it 'handles new players with zero games' do
        player_rating, task_rating = Elo.calculate_ratings(
          1200, 1200,
          player_won: true,
          player_games: 0,
          task_games: 0
        )

        player_rating.should > 1200
        task_rating.should < 1200
        player_rating.should be_a(Integer)
        task_rating.should be_a(Integer)
      end

      it 'handles very experienced players' do
        player_rating, task_rating = Elo.calculate_ratings(
          1200, 1200,
          player_won: true,
          player_games: 500,
          task_games: 500
        )

        player_change = player_rating - 1200
        player_change.should <= 15
      end
    end

    context 'mathematical properties' do
      it 'maintains approximately zero-sum property for equal ratings' do
        player_rating, task_rating = Elo.calculate_ratings(
          1200, 1200,
          player_won: true,
          player_games: 50,
          task_games: 50
        )

        total_change = (player_rating - 1200) + (task_rating - 1200)
        total_change.abs.should < 10
      end

      it 'produces consistent results for identical inputs' do
        result1 = Elo.calculate_ratings(
          1350, 1280,
          player_won: true,
          player_games: 25,
          task_games: 40
        )

        result2 = Elo.calculate_ratings(
          1350, 1280,
          player_won: true,
          player_games: 25,
          task_games: 40
        )

        result1.should eq(result2)
      end

      it 'produces different results for opposite outcomes' do
        win_result = Elo.calculate_ratings(
          1200, 1200,
          player_won: true,
          player_games: 50,
          task_games: 50
        )

        loss_result = Elo.calculate_ratings(
          1200, 1200,
          player_won: false,
          player_games: 50,
          task_games: 50
        )

        win_result[0].should > loss_result[0]
        win_result[1].should < loss_result[1]
      end
    end

    context 'return value format' do
      it 'returns an array of two integers' do
        result = Elo.calculate_ratings(
          1200, 1200,
          player_won: true,
          player_games: 50,
          task_games: 50
        )

        result.should be_an(Array)
        result.length.should eq(2)
        result[0].should be_a(Integer)
        result[1].should be_a(Integer)
      end
    end
  end

  describe 'constants' do
    it 'has expected constant values' do
      Elo::BASE_K_FACTOR.should eq(32)
      Elo::UPSET_MULTIPLIER.should eq(2.5)
      Elo::EXPECTED_THRESHOLD.should eq(0.25)
      Elo::MIN_RATING_CHANGE.should eq(1)
      Elo::MAX_K_FACTOR.should eq(80)
    end
  end
end
