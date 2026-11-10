# What a nickname may be. It is the one piece of text a child writes that other
# children see — on the weekly board, in the duel lobby, in a friend request
# and in the notification on somebody else's lock screen — and until this there
# was no rule at all: it could be another child's nickname, „Админ", an
# obscenity or ten thousand characters.
#
# The rules are checked only when the nickname changes (User), so nobody who
# chose one before them is locked out of saving anything else.
module NicknameRules
  LENGTH = 2..20
  # Letters of any alphabet, digits, and the few marks children join words with.
  FORMAT = /\A[\p{L}\p{N}][\p{L}\p{N} ._-]*\z/
  # Names that would pass for the people who run the place.
  RESERVED = %w[admin administrator админ администратор moderator модератор wunderkind вундеркинд support поддръжка учител teacher].freeze
  # Stems, matched anywhere in the nickname once everything but letters is
  # dropped and look-alike digits are read as letters. Short and made of
  # stems no ordinary word contains, on purpose: „еба" would refuse „Хлебар"
  # and „кур" a „Куриер", and a child told their own name is rude learns only
  # that the app is broken.
  OFFENSIVE = %w[
    fuck shit bitch cunt pussy nigg faggot porn penis vagina
    пичк путк курв курец хуй шибан шибам ебал ебан ебах заеб наеб мамкат педер гъз лайно пишк минет порно секс
  ].freeze
  LOOKALIKES = { "0" => "o", "1" => "i", "3" => "e", "4" => "a", "5" => "s", "@" => "a", "$" => "s" }.freeze

  module_function

  # nil when the nickname is fine, else the key of what is wrong with it.
  def problem(nickname)
    return :too_short if nickname.length < LENGTH.min
    return :too_long if nickname.length > LENGTH.max
    return :invalid unless nickname.match?(FORMAT)

    plain = nickname.downcase.gsub(/[#{Regexp.escape(LOOKALIKES.keys.join)}]/, LOOKALIKES).gsub(/[^\p{L}]/, "")
    return :reserved if RESERVED.include?(plain)
    return :offensive if OFFENSIVE.any? { |stem| plain.include?(stem) }

    nil
  end
end
