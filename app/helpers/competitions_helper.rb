module CompetitionsHelper
  # An exam lives under /izpiti and a competition under /sastezaniya.
  def event_page_path(event)
    event.exam? ? exam_page_path(event.slug) : competition_page_path(event.slug)
  end

  # „1.–4. клас", or „7. клас" for an exam that is one grade's.
  def event_grades(event)
    if event.grade_min == event.grade_max
      t("competitions.grades_one", grade: event.grade_min)
    else
      t("competitions.grades_span", from: event.grade_min, to: event.grade_max)
    end
  end

  # „18 март 2027", with „около" in front of a date nobody has published yet.
  def round_date(round)
    date = l(round.date, format: :long)
    round.approximate? ? t("competitions.approximate_date", date: date) : date
  end

  # „днес", „утре", „след 12 дни" — the countdown a child reads.
  def days_until(round)
    days = round.days_until
    return t("competitions.today") if days.zero?
    return t("competitions.tomorrow") if days == 1

    t("competitions.in_days", count: days)
  end
end
