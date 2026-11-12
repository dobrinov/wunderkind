# /matematika/formuli and /matematika/formuli/:view — the formula sheets (see
# Formulas). The hub holds every formula; a view is one grade (7-klas) or one
# exam sheet (nvo-7-klas, matura), each its own page because each is its own
# search. Public, crawlable, open to a signed-in visitor too, like the rest of
# the content pages.
class FormulasController < ApplicationController
  layout "landingpage"

  def index
    @view = Formulas::ALL
    render_sheet
  end

  def show
    @view = Formulas.view(params[:view]) || raise(ActionController::RoutingError, "No such sheet")
    render_sheet
  end

  private

  def render_sheet
    @topics = Formulas.for(@view)
    @without_formulas = Formulas.without_formulas(@view)
    names = @topics.map(&:first) + @without_formulas
    @topic_records = Topic.where.not(parent_id: nil).where(name: names).index_by(&:name)
    @explainers = Explainers.all.index_by(&:topic_name)
    @count = @topics.sum { |_, formulas| formulas.size }

    seo title: title,
        description: t("seo.formulas.#{key}.description", **interpolations, count: @count),
        canonical_path: path,
        indexable: true,
        schema: breadcrumbs

    render :index
  end

  # Which wording the page takes: the hub, a grade, an НВО sheet, the матура.
  def key
    if @view.all? then "index"
    elsif @view.grade? then "grade"
    elsif @view.slug == "matura" then "matura"
    else "nvo"
    end
  end
  helper_method :key

  def interpolations = { grade: @view.grade }
  helper_method :interpolations

  def title = t("seo.formulas.#{key}.title", **interpolations)

  def path = @view.all? ? formulas_path : formula_sheet_path(@view.slug)

  def breadcrumbs
    trail = { t("curriculum.breadcrumb") => curriculum_path, t("formulas.breadcrumb") => formulas_path }
    trail[t("formulas.#{key}.title", **interpolations)] = path unless @view.all?
    items = trail.each_with_index.map do |(name, item_path), index|
      { "@type" => "ListItem", "position" => index + 1, "name" => name, "item" => Seo.url(item_path) }
    end

    { "@context" => "https://schema.org", "@type" => "BreadcrumbList", "itemListElement" => items }
  end
end
