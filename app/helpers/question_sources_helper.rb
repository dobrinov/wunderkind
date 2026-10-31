module QuestionSourcesHelper
  # „СМТ 2024 · 3 клас · задача 5" for a problem from a past paper, „По модела
  # на задача 5 · СМТ 2024, 3 клас" for one of ours written on its model; nil
  # for everything else. Named by the competition's or exam's own short name
  # (config/competitions.yml), never by the site the paper was found on.
  def question_source_label(question)
    source = question.source.presence or return
    event = Competitions.find(source["competition"]) or return
    values = { name: event.short.presence || event.name.to_s, year: source["year"], grade: source["grade"],
               number: source["number"] }
    source["kind"] == "modelled" ? t("past_papers.label.modelled", **values) : t("past_papers.label.original", **values)
  end

  def question_source_title(question)
    event = question.source.present? && Competitions.find(question.source["competition"])
    event ? event.name.to_s : nil
  end
end
