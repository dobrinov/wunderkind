# Rewrites a problem's Bulgarian text from leva to euro: „24 лв." → „24 евро",
# „Колко лева" → „Колко евро", „10 стотинки" → „10 цента". Bulgaria has used
# the euro since 1 January 2026, and a child now meets „лв." only in old books.
#
# Words only — the numbers stay, because these are arithmetic problems about a
# price, not about what a thing really costs. Used by `rake problems:euro` on
# the site's own problems; past papers are left as they were printed.
module EuroWording
  # „лв" is only ever money. The word is not: „лева" is also "left" („лева
  # страна"), and „Лев" a name — so the word counts as money only where an
  # amount is being said: after a number, or after „колко" / „няколко".
  ABBREVIATION = /(?<![а-яА-Я])лв\.?(?![а-яА-Я])/
  WORD = /(?<=\d\s|\d|[Кк]олко\s|[Нн]яколко\s)лев(?:а|ове)?(?![а-яА-Я])/
  LEV = Regexp.union(ABBREVIATION, WORD)
  COIN = /(?<![а-яА-Я])стотинк(?:а|и|ата|ите)(?![а-яА-Я])/

  module_function

  def mentions?(text) = text.to_s.match?(LEV) || text.to_s.match?(COIN)

  def convert(text)
    text.to_s
        # „лв." before a lower-case word is an abbreviation's dot, which goes;
        # before a capital or at the end it is also the sentence's, which stays.
        .gsub(/(?<![а-яА-Я])лв\.(?=\s+[а-я0-9(—–-])/, "евро")
        .gsub(/(?<![а-яА-Я])лв\.(?=,|;|\))/, "евро")
        .gsub(/(?<![а-яА-Я])лв\./, "евро.")
        .gsub(ABBREVIATION, "евро")
        .gsub(WORD, "евро")
        .gsub(/(?<![а-яА-Я])(\d+)\s+стотинк(?:а|и)(?![а-яА-Я])/) { "#{$1} #{$1.to_i == 1 ? "цент" : "цента"}" }
        .gsub(/(?<![а-яА-Я])стотинката(?![а-яА-Я])/, "центът")
        .gsub(/(?<![а-яА-Я])стотинките(?![а-яА-Я])/, "центовете")
        .gsub(/(?<![а-яА-Я])стотинка(?![а-яА-Я])/, "цент")
        .gsub(/(?<![а-яА-Я])стотинки(?![а-яА-Я])/, "цента")
  end

  # The same rewrite through a RichContent document: every string in it.
  def convert_doc(node)
    case node
    when String then convert(node)
    when Array then node.map { |child| convert_doc(child) }
    when Hash then node.transform_values { |value| convert_doc(value) }
    else node
    end
  end
end
