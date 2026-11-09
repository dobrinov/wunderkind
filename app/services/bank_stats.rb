# What the landing page says about the question bank: how many problems, how
# they are answered, how many come from real papers, how they spread over the
# grades. Never a problem itself — only counts of published ones.
#
# The figures have to follow the bank, not a clock: an import, a retirement or
# a deletion should show on the next visit, not tomorrow. So the snapshot is
# cached under a fingerprint of the questions table — the published count and
# the newest `updated_at` — and the fingerprint is the only query a visit runs.
# Adding or deleting a published question moves the count; publishing,
# retiring or editing one moves `updated_at`. (A raw `update_all` that skips
# `updated_at` slips past, and the snapshot then lapses within EXPIRY.)
class BankStats
  # Below this the bank is not worth quoting, and the page says nothing.
  MINIMUM = 500
  EXPIRY = 1.week
  GRADES = 1..12

  Snapshot = Data.define(
    :total, :explained_percent, :answer_types, :widget_kinds,
    :past_papers, :past_paper_years, :with_figure, :by_grade
  )

  class << self
    def current
      Rails.cache.fetch([ "bank_stats", fingerprint ], expires_in: EXPIRY) { compute }
    rescue ActiveRecord::StatementInvalid
      # A landing page that 500s because a migration is mid-flight is worse
      # than a landing page missing its numbers.
      nil
    end

    # "19 500" is no less true than 19 543, and it does not change on every
    # import. Small counts keep their tens, so 360 is not quoted as 300.
    def floor(count)
      step = count >= 1000 ? 100 : 10
      count - (count % step)
    end

    private

    def fingerprint
      count, latest = Question.pick(
        Arel.sql(Question.sanitize_sql_array([ "count(*) FILTER (WHERE status = ?)", Question.statuses.fetch("published") ])),
        Arel.sql("max(updated_at)")
      )
      "#{count}-#{latest&.to_fs(:usec)}"
    end

    def compute
      bank = Question.published
      total = bank.count
      return if total < MINIMUM

      years = bank.where("source ->> 'kind' = 'original'")
                  .pick(Arel.sql("min((source ->> 'year')::int)"), Arel.sql("max((source ->> 'year')::int)"))
      grades = bank.where(taught_from_grade: GRADES).group(:taught_from_grade).count

      Snapshot.new(
        total: total,
        explained_percent: bank.where.not(explanation: [ nil, "" ]).count * 100 / total,
        answer_types: answer_types(bank, total),
        widget_kinds: bank.interactive.distinct.count(Arel.sql("grading ->> 'widget'")),
        past_papers: bank.where("source ->> 'kind' = 'original'").count,
        past_paper_years: years.compact.size == 2 ? Range.new(*years) : nil,
        with_figure: bank.where(attachable_type: "QuestionImage").count,
        by_grade: GRADES.index_with { |grade| grades.fetch(grade, 0) }
      )
    end

    # Share of each answer kind, most common first. Free text is left out: the
    # page describes how a child answers, and nothing in the bank asks for an
    # essay any more.
    def answer_types(bank, total)
      bank.where(answer_type: %i[interactive exact_value multiple_choice])
          .group(:answer_type).count
          .sort_by { |_, count| -count }
          .map { |type, count| [ type.to_sym, (count * 100.0 / total).round ] }
          .to_h
    end
  end
end
