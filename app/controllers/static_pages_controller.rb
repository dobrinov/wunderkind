class StaticPagesController < ApplicationController
  layout "landingpage"

  # The bank size is the one figure on the landing page that is not a constant,
  # and it is the one visitors care about most. Cached for a day and floored to a
  # round hundred: the exact count changes with every import and "19 500 задачи"
  # is no less true than 19 543.
  BANK_CACHE_TTL = 1.day
  BANK_MINIMUM = 500

  def landingpage
    return redirect_to home_path_for(current_user) if current_user

    @bank_size = bank_size

    # The one page a visitor can reach without an account, so the one page whose
    # title and description have to carry the words a parent typed rather than
    # just the brand — nobody searches for a brand they have not heard of.
    seo title: t("seo.landing.title"),
        description: t("seo.landing.description", minutes: DailyPractice::DEFAULT_MINUTES),
        canonical_path: root_path,
        indexable: true,
        schema: faq_schema
  end

  private

  # The FAQ that is already on the page, in the vocabulary Google gives a rich
  # result to. It has to mirror the section exactly — marking up an answer that
  # is not on the page is what the guidelines call out — so both read the same
  # four translation keys.
  FAQ_KEYS = %w[age time not_taught authoring].freeze

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

  def bank_size
    size = Rails.cache.fetch("landing/bank_size", expires_in: BANK_CACHE_TTL) do
      Question.published.count
    end

    size >= BANK_MINIMUM ? size - (size % 100) : nil
  rescue ActiveRecord::StatementInvalid
    # A landing page that 500s because a migration is mid-flight is worse than a
    # landing page missing one number.
    nil
  end
end
