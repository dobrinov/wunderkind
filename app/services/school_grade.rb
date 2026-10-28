# The school grade a child is probably in, worked out from the optional birth
# year a parent or the child gave and how far their school start sits from the
# usual one.
#
# The rule is the school act's (ЗПУО): a child starts first grade in the
# calendar year they turn seven (six, if the parent asks), and moves up a
# grade every 15 September. A child who started a year early has an offset of
# +1, one who started a year late — or repeated a year — -1. That is an estimate and stays one: nothing
# here is a record of what school the child goes to.
#
# Read by the settings form, the parent's pages and the admin user list. The
# answer flow does not read it — difficulty is still the question's Elo and
# ability the student's — so storing a birth year changes nothing a child is
# asked until something is deliberately built on it.
module SchoolGrade
  # The ages the forms offer: a four-year-old starting early to a nineteen-
  # year-old in their last year, with room either side.
  YOUNGEST = 3
  OLDEST = 20

  # The offsets the form offers, earliest start first, by their locale key.
  OFFSETS = { 2 => "early_2", 1 => "early_1", 0 => "on_time", -1 => "late_1", -2 => "late_2" }.freeze
  GRADES = (1..12).freeze

  module_function

  # The calendar year the current school year began in: September onwards is
  # this year's, January to August still last year's.
  def school_year_start(on = Time.zone.today)
    on.month >= 9 ? on.year : on.year - 1
  end

  # The grade, or :preschool before first grade and :finished after twelfth;
  # nil without a birth year.
  def estimate(birth_year, offset: 0, on: Time.zone.today)
    return if birth_year.blank?

    grade = school_year_start(on) - birth_year.to_i - 6 + offset.to_i
    if grade < GRADES.min then :preschool
    elsif grade > GRADES.max then :finished
    else grade
    end
  end

  # The birth years a form offers, youngest first.
  def birth_years(on = Time.zone.today)
    (on.year - OLDEST..on.year - YOUNGEST).to_a.reverse
  end

  # How the estimate reads: „≈ 3 клас", „преди училище", „завършил".
  def label(grade)
    case grade
    when nil then nil
    when Symbol then I18n.t("school_grade.#{grade}")
    else I18n.t("school_grade.grade", grade: grade)
    end
  end
end
