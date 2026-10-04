module ChallengeHelpers
  # What the ready room does between the lobby filling and the first problem:
  # both players press „Готов съм" and the countdown runs out. Specs that are
  # about the match rather than about getting into one call this.
  def start_duel!(challenge)
    challenge.participants.each { |participant| ChallengeLobby.ready!(challenge, participant) }
    challenge.update!(starts_at: 1.second.ago)
    ChallengeLobby.begin!(challenge)

    challenge.reload
  end

  # The same thing through the HTTP the players actually use. Leaves the
  # session signed in as whoever pressed last, so callers sign in again.
  def ready_up!(challenge, players)
    players.each do |player|
      sign_in player
      post "/challenges/#{challenge.id}/ready"
    end

    challenge.reload.update!(starts_at: 1.second.ago)
    ChallengeLobby.begin!(challenge)

    challenge.reload
  end

  # Two players into a live match through the screens they actually use: both
  # press the button, both ready up, the countdown runs out.
  def duel!(host, guest)
    sign_in host
    post "/challenges"
    sign_in guest
    post "/challenges"

    ready_up!(Challenge.last, [ host, guest ])
  end

  # A match under way between two fresh players.
  def duel_between(host, guest)
    ChallengeMatchmaker.call(user: host)
    start_duel!(ChallengeMatchmaker.call(user: guest))
  end
end

RSpec.configure do |config|
  config.include ChallengeHelpers
end
