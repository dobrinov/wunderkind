class StaticPagesController < ApplicationController
  layout "landingpage"

  def landingpage
    return redirect_to home_path_for(current_user) if current_user

    # The only figures on the page that are not constants: counts of the
    # published bank, refreshed whenever it changes (see BankStats).
    @bank = BankStats.current
    # The competitions door — the exams' is `public_exams`, shared with the menu.
    @upcoming_competitions = Competitions.upcoming.select(&:competition?).first(3)

    # The one page a visitor can reach without an account, so the one page whose
    # title and description have to carry the words a parent typed rather than
    # just the brand — nobody searches for a brand they have not heard of.
    seo title: t("seo.landing.title"),
        description: t("seo.landing.description", minutes: DailyPractice::DEFAULT_MINUTES),
        canonical_path: root_path,
        indexable: true,
        schema: faq_schema
  end

  # „За родители": how it works, at the length the landing page used to say
  # it. Open to a signed-in visitor too, like the other content pages.
  def parents
    seo title: t("seo.parents.title"),
        description: t("seo.parents.description", minutes: DailyPractice::DEFAULT_MINUTES),
        canonical_path: for_parents_path,
        indexable: true
  end

  private

  # The FAQ that is already on the page, in the vocabulary Google gives a rich
  # result to. It has to mirror the section exactly — marking up an answer that
  # is not on the page is what the guidelines call out — so both read the same
  # translation keys. The answers are folded there (<details>), and on the
  # page all the same.
  FAQ_KEYS = %w[age time not_taught authoring competitions matura].freeze

  def faq_schema
    questions = FAQ_KEYS.map do |key|
      {
        "@type" => "Question",
        "name" => t("landing.faq.#{key}.q"),
        "acceptedAnswer" => { "@type" => "Answer", "text" => faq_answer(key) }
      }
    end

    { "@context" => "https://schema.org", "@type" => "FAQPage", "mainEntity" => questions }
  end

  def faq_answer(key)
    t("landing.faq.#{key}.a", minutes: DailyPractice::DEFAULT_MINUTES,
                              days: AnswerSubmission::DEFERRAL_DAYS)
  end
end
