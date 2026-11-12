module QuestionSourcesHelper
  # „СМТ 2024 · 3 клас · задача 5" for a problem from a past paper, „По модела
  # на задача 5 · СМТ 2024, 3 клас" for one of ours written on its model; nil
  # for everything else. Named by the competition's or exam's own short name
  # (the competitions tables), never by the site the paper was found on.
  #
  # The grade only where it is the point — sitting that paper, or the list of
  # where a type was set. Anywhere else a problem is served because it suits
  # the child's rating, and „3 клас" on it tells a twelve-year-old the app
  # thinks they are eight (every older child in the agent field test said so).
  def question_source_label(question, grade: true)
    source = question.source.presence or return
    event = Competitions.find(source["competition"]) or return
    values = { name: event.short.presence || event.name.to_s, year: PastPapers.edition(event.slug, source["year"], source["round"]), grade: source["grade"],
               number: source["number"] }
    key = source["kind"] == "modelled" ? "modelled" : "original"
    t("past_papers.label.#{key}#{"_gradeless" unless grade}", **values)
  end

  def question_source_title(question)
    event = question.source.present? && Competitions.find(question.source["competition"])
    event ? event.name.to_s : nil
  end
end
