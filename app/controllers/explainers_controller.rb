# /matematika/obyasneno and /matematika/obyasneno/:slug — the "Обяснено
# просто" articles (see Explainers). Public, crawlable, and open to a signed-in
# visitor too, like the rest of the content pages.
class ExplainersController < ApplicationController
  layout "landingpage"

  def index
    @bands = Explainers.by_band

    seo title: t("seo.explainers.index.title"),
        description: t("seo.explainers.index.description"),
        canonical_path: explainers_path,
        indexable: true,
        schema: breadcrumbs(t("curriculum.breadcrumb") => curriculum_path, t("explainers.breadcrumb") => explainers_path)
  end

  def show
    @article = Explainers.find(params[:slug]) || not_found
    @topic = @article.topic
    @samples = @topic ? Curriculum.sample_questions(elo_range: 0.., topic: @topic, limit: 4) : []
    @related = @article.related.filter_map { |slug| Explainers.find(slug) }

    seo title: @article.seo_title,
        description: @article.seo_description,
        canonical_path: explainer_path(@article.slug),
        indexable: true,
        schema: [ article_schema, breadcrumbs(t("curriculum.breadcrumb") => curriculum_path,
                                              t("explainers.breadcrumb") => explainers_path,
                                              @article.title => explainer_path(@article.slug)) ]
  end

  private

  # An explanation for learners, said in the vocabulary Google reads for one.
  def article_schema
    {
      "@context" => "https://schema.org",
      "@type" => "LearningResource",
      "name" => @article.title,
      "headline" => @article.title,
      "description" => @article.seo_description,
      "url" => Seo.url(explainer_path(@article.slug)),
      "inLanguage" => I18n.locale.to_s,
      "isAccessibleForFree" => true,
      "learningResourceType" => "explanation",
      "interactivityType" => "mixed",
      "educationalLevel" => t("explainers.grades", grades: @article.grade_label),
      "timeRequired" => "PT#{@article.minutes}M",
      "publisher" => { "@id" => "#{Seo.origin}/#organization" }
    }
  end

  def breadcrumbs(trail)
    items = trail.each_with_index.map do |(name, path), index|
      { "@type" => "ListItem", "position" => index + 1, "name" => name, "item" => Seo.url(path) }
    end

    { "@context" => "https://schema.org", "@type" => "BreadcrumbList", "itemListElement" => items }
  end

  def not_found
    raise ActionController::RoutingError, "No such page"
  end
end
