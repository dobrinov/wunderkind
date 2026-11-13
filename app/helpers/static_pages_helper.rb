module StaticPagesHelper
  # Which of the public menu's five destinations the current page is under, so
  # the header can mark it: a visitor from a search lands deep in the site and
  # the menu is the only thing telling them where.
  PUBLIC_SECTIONS = {
    "curriculum" => :problems, "grade_tests" => :problems, "worksheets" => :problems,
    "explainers" => :tools, "formulas" => :tools, "calculators" => :tools, "times_tables" => :tools
  }.freeze

  def public_section
    case controller_name
    when "competition_pages" then exam_page? ? :exams : :competitions
    when "static_pages" then (:parents if action_name == "parents")
    else PUBLIC_SECTIONS[controller_name]
    end
  end

  # The four exams in school order (НВО 4, 7, 10, the матура), for the menu,
  # the footer and the landing page's door.
  def public_exams
    @public_exams ||= Competitions.exams.sort_by { |exam| exam.grade_page || 99 }
  end

  private

  def exam_page?
    action_name == "exams" || request.path.start_with?("/izpiti")
  end
end
