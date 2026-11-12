# /matematika/tablitsa-za-umnozhenie — the multiplication table: the table
# itself, each row written out, and a ten-question check of one row or of all
# of it. Public and crawlable like the other content pages.
#
# „таблица за умножение" is typed in September and again in January, by the
# parent of a second- or third-grader, and usually with „за принтиране" or „и
# деление" after it — so the page prints, and a tapped cell shows the two
# divisions that come out of its product. Nothing is stored and nobody's
# rating moves: the check is a toy on a public page, and the real practice is
# the bank's 7 646 arithmetic facts behind the sign-up.
class TimesTablesController < ApplicationController
  layout "landingpage"

  RANGE = (1..10)

  def show
    @range = RANGE
    @topic = Topic.where.not(parent_id: nil).find_by(name: "Умножение и деление")

    seo title: t("seo.times_table.title"),
        description: t("seo.times_table.description"),
        canonical_path: times_table_path,
        indexable: true,
        schema: [ resource_schema, breadcrumbs ]
  end

  private

  def resource_schema
    {
      "@context" => "https://schema.org",
      "@type" => "LearningResource",
      "name" => t("times_table.title"),
      "description" => t("seo.times_table.description"),
      "url" => Seo.url(times_table_path),
      "inLanguage" => I18n.locale.to_s,
      "isAccessibleForFree" => true,
      "learningResourceType" => "practice",
      "interactivityType" => "active",
      "educationalLevel" => t("explainers.grades", grades: "2–4"),
      "publisher" => { "@id" => "#{Seo.origin}/#organization" }
    }
  end

  def breadcrumbs
    trail = { t("curriculum.breadcrumb") => curriculum_path, t("times_table.breadcrumb") => times_table_path }
    items = trail.each_with_index.map do |(name, path), index|
      { "@type" => "ListItem", "position" => index + 1, "name" => name, "item" => Seo.url(path) }
    end

    { "@context" => "https://schema.org", "@type" => "BreadcrumbList", "itemListElement" => items }
  end
end
