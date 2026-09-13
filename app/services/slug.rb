# Latin URL segments for Bulgarian names.
#
# `String#parameterize` drops every character it cannot fold to ASCII, so a
# Cyrillic topic name parameterizes to the empty string and Topic's slug fell
# back to `SecureRandom.hex` — fine while nothing linked to a topic, useless the
# moment a topic became a public URL. A crawler and a parent both read the path,
# and /matematika/tema/umnozhenie-i-delenie says what /matematika/tema/cd6116fb
# does not.
#
# The table is the official streamlined system (Закон за транслитерацията), the
# one Bulgarian passports and road signs use, so the spellings are the ones a
# reader already expects.
module Slug
  module_function

  LETTERS = {
    "а" => "a",  "б" => "b",  "в" => "v",  "г" => "g",  "д" => "d",
    "е" => "e",  "ж" => "zh", "з" => "z",  "и" => "i",  "й" => "y",
    "к" => "k",  "л" => "l",  "м" => "m",  "н" => "n",  "о" => "o",
    "п" => "p",  "р" => "r",  "с" => "s",  "т" => "t",  "у" => "u",
    "ф" => "f",  "х" => "h",  "ц" => "ts", "ч" => "ch", "ш" => "sh",
    "щ" => "sht", "ъ" => "a", "ь" => "y",  "ю" => "yu", "я" => "ya"
  }.freeze

  def call(text)
    latin = text.to_s.unicode_normalize(:nfc).downcase.chars.map { |char| LETTERS.fetch(char, char) }.join
    latin.parameterize(separator: "-").presence
  end
end
