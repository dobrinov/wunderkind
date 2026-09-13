# The public content pages: /matematika, /matematika/3-klas, /matematika/tema/drobi.
#
# The landing page can rank for the brand and for little else — a visitor who
# has not heard of Wunderkind never types it. What a parent types is "задачи по
# математика за 3 клас" or "упражнения по математика за 2 клас за принтиране",
# and these pages are the ones that answer that: a real slice of the bank, with
# the worked explanation under each problem, so the page stands on its own for
# someone who never signs up and earns the right to invite the ones who would.
#
# Everything here is read-only, cached, and open to a signed-in visitor too — a
# parent following a link from a search result should land on the page, not on
# their own dashboard.
class CurriculumController < ApplicationController
  layout "landingpage"

  # These pages change only when the bank does, which is an import, not a
  # request. A crawler hitting sixty of them should not run sixty topic
  # aggregations.
  CACHE_TTL = 12.hours

  def index
    @grades = Curriculum.grades
    @topic_groups = cached("curriculum/index/topics") { topic_groups }

    seo title: t("seo.curriculum.index.title"),
        description: t("seo.curriculum.index.description"),
        canonical_path: curriculum_path,
        indexable: true,
        schema: breadcrumbs(t("curriculum.breadcrumb") => curriculum_path)
  end

  def grade
    @grade = Curriculum.grade(params[:grade]) || not_found
    @topics = cached("curriculum/grade/#{@grade.slug}/topics") { Curriculum.topics_for(@grade) }
    @question_count = cached("curriculum/grade/#{@grade.slug}/count") { Curriculum.question_count(@grade) }
    @samples = Curriculum.sample_questions(elo_range: @grade.range)

    seo title: grade_title,
        description: t("seo.curriculum.grade.description", grade: @grade.number,
                                                           count: rounded(@question_count)),
        canonical_path: curriculum_grade_path(@grade.slug),
        indexable: true,
        schema: grade_schema
  end

  def topic
    @topic = Curriculum.find_topic(params[:slug]) || not_found
    @grades = cached("curriculum/topic/#{@topic.slug}/grades") { Curriculum.grades_for(@topic) }
    @question_count = cached("curriculum/topic/#{@topic.slug}/count") { @topic.questions.published.count }
    @samples = Curriculum.sample_questions(elo_range: 0.., topic: @topic)

    seo title: t("seo.curriculum.topic.title", topic: @topic.name),
        description: t("seo.curriculum.topic.description", topic: @topic.name,
                                                           count: rounded(@question_count)),
        canonical_path: curriculum_topic_path(@topic.slug),
        indexable: true,
        schema: topic_schema
  end

  private

  # "НВО 4 клас математика" and "НВО 7 клас математика" are queries of their own,
  # with their own season, and they are worth the room in the title on the two
  # grades that have an exam at the end. The other five keep the plain pattern.
  def grade_title
    key = @grade.exam? ? "exam_title" : "title"
    t("seo.curriculum.grade.#{key}", grade: @grade.number)
  end

  # Root topics with their practisable children, for the hub page's directory.
  def topic_groups
    counts = Question.published.joins(:topics).group("topics.id").count

    Topic.roots.ordered.includes(:children).filter_map do |root|
      children = root.children.sort_by(&:position).select { |child| counts.fetch(child.id, 0) >= Curriculum::MINIMUM_PER_TOPIC }
      next if children.empty?

      [ root, children.map { |child| [ child, counts.fetch(child.id, 0) ] } ]
    end
  end

  # A count in a description is a promise, and "6630" reads like a machine
  # wrote it. The hundred below is true and sounds like a person.
  def rounded(count)
    return count if count < 100

    number_with_delimiter(count - (count % 100), delimiter: " ")
  end

  def number_with_delimiter(...) = view_context.number_with_delimiter(...)

  # The page *is* a practice course in a grade, so it says so in the vocabulary
  # Google has a rich result for. `isAccessibleForFree` is the honest answer:
  # the problems on the page are, the app behind them needs an account.
  def grade_schema
    {
      "@context" => "https://schema.org",
      "@type" => "Course",
      "name" => grade_title,
      "description" => t("seo.curriculum.grade.description", grade: @grade.number, count: rounded(@question_count)),
      "url" => Seo.url(curriculum_grade_path(@grade.slug)),
      "inLanguage" => "bg",
      "isAccessibleForFree" => true,
      "educationalLevel" => t("curriculum.grade_name", number: @grade.number),
      "teaches" => @topics.map { |topic, _| topic.name },
      "provider" => { "@id" => "#{Seo.origin}/#organization" },
      "hasCourseInstance" => {
        "@type" => "CourseInstance",
        "courseMode" => "online",
        "courseWorkload" => "PT#{DailyPractice::DEFAULT_MINUTES}M"
      }
    }
  end

  def topic_schema
    breadcrumbs(
      t("curriculum.breadcrumb") => curriculum_path,
      @topic.name => curriculum_topic_path(@topic.slug)
    )
  end

  def breadcrumbs(trail)
    items = trail.each_with_index.map do |(name, path), index|
      { "@type" => "ListItem", "position" => index + 1, "name" => name, "item" => Seo.url(path) }
    end

    { "@context" => "https://schema.org", "@type" => "BreadcrumbList", "itemListElement" => items }
  end

  def cached(key, &)
    Rails.cache.fetch(key, expires_in: CACHE_TTL, &)
  end

  def not_found
    raise ActionController::RoutingError, "No such page"
  end
end
