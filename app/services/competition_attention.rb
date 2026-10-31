# What a competition needs from the team, for /overseer/competitions: the
# calendar goes stale on its own — a round passes, next year's date is not in,
# a paper is published and nobody files it — and nothing else would say so.
module CompetitionAttention
  Flag = Struct.new(:key, :year, keyword_init: true)

  module_function

  def for(event, today = Time.zone.today)
    flags = []
    next_round = event.next_round(today)
    if next_round.nil?
      flags << Flag.new(key: :no_next_date)
    elsif next_round.approximate?
      flags << Flag.new(key: :approximate, year: event.editions.find { |edition| edition.rounds.include?(next_round) }&.year)
    end
    # A competition we file papers for should have the last one held.
    papers = PastPapers.originals(event.slug).distinct.pluck(Arel.sql("questions.source ->> 'year'")).map(&:to_i)
    held = event.editions.select { |edition| edition.held?(today) }.map(&:year).max
    flags << Flag.new(key: :paper_missing, year: held) if papers.any? && held && !papers.include?(held)
    flags
  end
end
