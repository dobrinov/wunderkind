# /matematika/3-klas/raboten-list and /matematika/3-klas/drobi/raboten-list —
# a worksheet to print: a grade's problems, or one topic's in that grade, on
# the first page and the answers on the second.
#
# „задачи по математика за 1 клас за принтиране" is the one query on the head
# term that keeps rising, and what is wanted is paper: a sheet a child fills in
# with a pencil and a parent marks from the key. So the page is laid out as the
# sheet itself — on screen a preview with a „Принтирай" button, in print
# nothing but the sheet — and its problems are not the ones the grade page, the
# topic page or the test already show (Curriculum.worksheet_questions), so the
# three are three sets of practice rather than one set three times.
class WorksheetsController < ApplicationController
  layout "landingpage"

  def show
    @grade = Curriculum.grade(params[:grade]) || not_found
    @topic = find_topic if params[:slug]
    @questions = Curriculum.worksheet_questions(@grade, topic: @topic)
    not_found if @questions.size < Curriculum::WORKSHEET_MINIMUM

    seo title: t("seo.curriculum.worksheet.#{key}.title", **names),
        description: t("seo.curriculum.worksheet.#{key}.description", **names, count: @questions.size),
        canonical_path: path,
        indexable: true,
        schema: breadcrumbs
  end

  private

  # Only where the topic has a page in this grade: the same rule as that page.
  def find_topic
    topic = Curriculum.find_topic(params[:slug]) || not_found
    Curriculum.grade_topic?(@grade, topic) ? topic : not_found
  end

  def key = @topic ? "topic" : "grade"
  helper_method :key

  def names = { grade: @grade.number, topic: @topic&.name }
  helper_method :names

  def path
    @topic ? curriculum_grade_topic_worksheet_path(@grade.slug, @topic.slug) : curriculum_grade_worksheet_path(@grade.slug)
  end
  helper_method :path

  def breadcrumbs
    trail = { t("curriculum.breadcrumb") => curriculum_path, @grade.name => curriculum_grade_path(@grade.slug) }
    trail[@topic.name] = curriculum_grade_topic_path(@grade.slug, @topic.slug) if @topic
    trail[t("curriculum.worksheet.breadcrumb")] = path
    items = trail.each_with_index.map do |(name, item_path), index|
      { "@type" => "ListItem", "position" => index + 1, "name" => name, "item" => Seo.url(item_path) }
    end

    { "@context" => "https://schema.org", "@type" => "BreadcrumbList", "itemListElement" => items }
  end

  def not_found
    raise ActionController::RoutingError, "No such page"
  end
end
