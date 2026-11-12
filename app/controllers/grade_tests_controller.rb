# /matematika/4-klas/test — a grade's test: ten problems from the bank across
# the grade's programme, answered on one page and marked when it is handed in.
#
# „тестове по математика за 4 клас с отговори" is what a parent types before a
# school test, and what they want is a paper: all the problems at once, then
# the answers. So unlike the trial (one problem at a time, on the practice
# card) this is a form — which also means it works with no JavaScript and
# prints. The marking is the real Grading, so „0,5" and „1/2" are the same
# answer here as in the app; nothing is stored and nobody's rating moves, since
# a visitor is not a calibrated student and the page does not know who sat it.
class GradeTestsController < ApplicationController
  layout "landingpage"

  before_action :set_grade

  def show
    seo title: t("seo.curriculum.test.title", grade: @grade.number),
        description: t("seo.curriculum.test.description", grade: @grade.number, count: @questions.size),
        canonical_path: grade_test_path(@grade.slug),
        indexable: true,
        schema: breadcrumbs
  end

  # Marks what was handed in and shows the same page with the verdicts. Not a
  # redirect: there is nowhere to keep the answers between two requests, and a
  # marked paper is not a page anyone should land on from a search.
  def create
    answers = params.fetch(:answers, {})
    @results = @questions.to_h do |question|
      raw = answers[question.id.to_s]
      raw = raw.respond_to?(:permit) ? raw.permit(:value, selected_ids: []) : {}
      [ question.id, mark(question, raw) ]
    end
    @score = @results.values.count(&:correct)

    seo title: t("seo.curriculum.test.title", grade: @grade.number), canonical_path: grade_test_path(@grade.slug)
    render :show
  end

  private

  Mark = Struct.new(:correct, :blank, :given, keyword_init: true)

  def mark(question, raw)
    return Mark.new(correct: false, blank: true, given: nil) if Grading.blank_response?(question: question, raw: raw)

    result = Grading.grade(question: question, raw: raw)
    Mark.new(correct: result.correct, blank: false, given: result.display_value)
  end

  def set_grade
    @grade = Curriculum.grade(params[:grade]) || raise(ActionController::RoutingError, "No such page")
    @questions = Curriculum.test_questions(@grade)
    raise ActionController::RoutingError, "No test for this grade" if @questions.empty?
  end

  def breadcrumbs
    trail = { t("curriculum.breadcrumb") => curriculum_path, @grade.name => curriculum_grade_path(@grade.slug),
              t("curriculum.test.breadcrumb") => grade_test_path(@grade.slug) }
    items = trail.each_with_index.map do |(name, path), index|
      { "@type" => "ListItem", "position" => index + 1, "name" => name, "item" => Seo.url(path) }
    end

    { "@context" => "https://schema.org", "@type" => "BreadcrumbList", "itemListElement" => items }
  end
end
