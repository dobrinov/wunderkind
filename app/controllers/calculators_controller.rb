# /matematika/formuli/:slug — a calculator page for one figure or solid (see
# Calculators). Public and crawlable like the other content pages.
class CalculatorsController < ApplicationController
  layout "landingpage"

  def show
    @calculator = Calculators.find(params[:slug]) || raise(ActionController::RoutingError, "No such calculator")
    @topic = @calculator.topic
    @samples = Calculators.samples(@calculator)
    @formulas = Formulas.all.select { |formula| formula.calculator == @calculator.slug }
    @related = @calculator.related.filter_map { |slug| Calculators.find(slug) }
    @explainer = @topic && Explainers.for_topic(@topic).first

    seo title: @calculator.seo_title,
        description: @calculator.seo_description,
        canonical_path: calculator_path(@calculator.slug),
        indexable: true,
        schema: [ resource_schema, breadcrumbs ]
  end

  private

  def resource_schema
    {
      "@context" => "https://schema.org",
      "@type" => "LearningResource",
      "name" => @calculator.title,
      "description" => @calculator.seo_description,
      "url" => Seo.url(calculator_path(@calculator.slug)),
      "inLanguage" => I18n.locale.to_s,
      "isAccessibleForFree" => true,
      "learningResourceType" => "explanation",
      "interactivityType" => "active",
      "educationalLevel" => t("explainers.grades", grades: @calculator.grade_label),
      "publisher" => { "@id" => "#{Seo.origin}/#organization" }
    }
  end

  def breadcrumbs
    trail = { t("curriculum.breadcrumb") => curriculum_path, t("formulas.breadcrumb") => formulas_path,
              @calculator.title => calculator_path(@calculator.slug) }
    items = trail.each_with_index.map do |(name, path), index|
      { "@type" => "ListItem", "position" => index + 1, "name" => name, "item" => Seo.url(path) }
    end

    { "@context" => "https://schema.org", "@type" => "BreadcrumbList", "itemListElement" => items }
  end
end
