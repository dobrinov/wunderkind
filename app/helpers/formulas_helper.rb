module FormulasHelper
  # The grades a topic is taught in, as the line beside its heading:
  # „5.–7. клас", or „8. клас" when it is a single year.
  def formula_grades(topic_name)
    grades = Formulas.grades_for(topic_name)
    return t("formulas.beyond") if grades.empty?
    return t("formulas.grade_one", grade: grades.first) if grades.one?

    t("formulas.grade_range", from: grades.min, to: grades.max)
  end
end
