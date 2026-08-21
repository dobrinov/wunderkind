require "yaml"
require "fileutils"
require "digest"

require_relative "num"
require_relative "explain"
require_relative "svg"
require_relative "figures"
require_relative "widget_kit"

# The ladder builder.
#
# A *family* is one type of problem — "find the third angle of a triangle",
# "percent of an amount", "solve ax + b = c". A family declares a ladder of
# rungs: the same type of problem at rising difficulty, one Elo rating per
# rung. The builder asks the family for a handful of variants per rung and
# writes them out as an importable problem file.
#
# That laddering is the whole point of the corpus. The dispatcher aims at a
# rating ~147 points below the student, so a student who keeps missing a type
# of problem drifts down its ladder until they meet the rung they can do, and
# climbs back up the same type as the rating recovers. For that to work the
# rungs of a family have to be *close* together (60-120 points) and cover a
# wide span, which is what `rungs:` is for.
#
# Everything is deterministic: variant parameters come from a Random seeded
# with the family name, the rung and the attempt number, so rebuilding the
# corpus produces byte-identical files and re-importing updates rather than
# duplicates.
module Authoring
  FAMILIES = []

  # Same-shape variants per rung, unless the family says otherwise.
  DEFAULT_VARIANTS = 6

  # How hard to try for distinct variants before giving up on a rung: small
  # parameter spaces (single-digit numbers) run out of distinct problems.
  ATTEMPT_FACTOR = 14

  class Duplicate < StandardError; end

  Family = Struct.new(:name, :topic, :area, :rungs, :variants, :block, keyword_init: true)

  # What a family's block builds. `figure` is an Svg::Figure; the builder turns
  # it into a PNG on disk and points the problem at it.
  Problem = Struct.new(:text, :answer, :explanation, :options, :widget, :rubric, :figure, :tolerance, :hints, keyword_init: true)

  class Context
    attr_reader :level, :levels, :rng

    def initialize(level:, levels:, rng:)
      @level = level
      @levels = levels
      @rng = rng
    end

    # Convenience for families whose wording changes at the top of the ladder.
    def top? = level == levels - 1
    def bottom? = level.zero?

    def int(range) = rng.rand(range)

    # An empty pool means this draw has no problem to give — the family skips
    # the attempt rather than blowing up the build.
    def pick(items)
      list = items.to_a
      raise Duplicate if list.empty?

      list[rng.rand(list.size)]
    end

    def sample(items, count) = items.to_a.shuffle(random: rng).first(count)

    def coin = rng.rand(2).zero?

    # Draws from `items` by rung: rung 0 gets the first entries, the top rung
    # the last. Used for a ladder whose difficulty is a list of contexts rather
    # than a number range.
    def by_level(items)
      list = items.to_a
      list[[ level, list.size - 1 ].min]
    end

    # `hints:` is the ladder the student can reveal one rung at a time before
    # answering, cheapest nudge first. It is not the explanation cut short: an
    # explanation is read *after* a wrong answer and states the answer, a hint
    # is read instead of giving up and must not. check.rb refuses a rung that
    # contains the answer.
    def q(text:, explanation:, answer: nil, options: nil, widget: nil, rubric: nil, figure: nil, tolerance: nil,
          hints: nil)
      Problem.new(text: tidy(text), answer: answer&.to_s, explanation: tidy(explanation),
                  options: options, widget: widget, rubric: rubric, figure: figure,
                  tolerance: tolerance,
                  hints: Array(hints).map { |rung| tidy(rung) }.reject(&:empty?).then { |rungs| rungs.empty? ? nil : rungs })
    end

    # Units like "лв." and "ч." end in a full stop of their own, so a sentence
    # that ends on one comes out with two. Rather than every family working
    # around it, the doubled stop is collapsed here — but only a doubled one,
    # never the three dots of an unfinished sequence.
    def tidy(text)
      text.to_s.strip.gsub(/[ \t]+\n/, "\n").gsub(/(?<!\.)\.\.(?!\.)/, ".").gsub(" ,", ",")
    end
  end

  module_function

  # rungs: Elo ratings, easiest first. variants: distinct problems per rung.
  def family(name, topic:, area:, rungs:, variants: DEFAULT_VARIANTS, &block)
    raise ArgumentError, "family #{name} needs at least two rungs" if rungs.size < 2
    raise ArgumentError, "duplicate family #{name}" if FAMILIES.any? { |f| f.name == name }

    FAMILIES << Family.new(name: name, topic: topic, area: area, rungs: rungs,
                           variants: variants, block: block)
  end

  def families = FAMILIES

  # Generates every family and returns the rows grouped by area, plus a report.
  #
  # `taken` is the set of question texts already in the bank. The importer keys
  # questions by their text, so a generated problem that repeats one would
  # overwrite an older authored question (and its explanation) rather than add
  # anything — those are dropped and counted.
  def generate(only: nil, taken: [])
    seen = taken.to_h { |text| [ normalize(text), :bank ] }
    rows = Hash.new { |hash, key| hash[key] = [] }
    report = { families: 0, problems: 0, short: [], collisions: 0, bank_clashes: [] }

    FAMILIES.each do |family|
      next if only && !family.name.start_with?(only)

      report[:families] += 1
      produced = 0

      family.rungs.each_with_index do |elo, level|
        wanted = family.variants
        got = 0
        attempt = 0

        while got < wanted && attempt < wanted * ATTEMPT_FACTOR
          seed = Digest::SHA256.hexdigest("#{family.name}|#{level}|#{attempt}").to_i(16) % (2**48)
          context = Context.new(level: level, levels: family.rungs.size, rng: Random.new(seed))
          attempt += 1

          problem =
            begin
              family.block.call(context)
            rescue Duplicate
              nil
            end
          next if problem.nil?

          key = normalize(problem.text)
          if seen.key?(key)
            report[:collisions] += 1
            report[:bank_clashes] << problem.text if seen[key] == :bank
            next
          end
          seen[key] = family.name

          rows[family.area] << row_for(family, problem, elo, level, got + 1)
          got += 1
          produced += 1
        end

        report[:short] << "#{family.name} rung #{level + 1}: #{got}/#{wanted}" if got < wanted
      end

      report[:problems] += produced
    end

    [ rows, report ]
  end

  def normalize(text) = text.to_s.downcase.gsub(/\s+/, " ").strip

  def row_for(family, problem, elo, level, index)
    # "family" is provenance, not data the app reads: the importer only looks at
    # the keys it knows, and this one says which ladder the problem came from so
    # the rungs stay legible to whoever opens the file.
    row = { "text" => problem.text, "topic" => family.topic, "family" => family.name }
    row["answer"] = problem.answer if problem.answer
    row["tolerance"] = problem.tolerance if problem.tolerance
    row["options"] = problem.options if problem.options
    row["widget"] = problem.widget if problem.widget
    row["rubric"] = problem.rubric if problem.rubric
    row["hints"] = problem.hints if problem.hints
    row["elo"] = elo
    row["explanation"] = problem.explanation
    if problem.figure
      slug = family.name.tr(".", "-")
      name = "#{slug}-#{level + 1}-#{index}"
      row["image"] = "db/seeds/images/#{slug}/#{name}.png"
      row["image_filename"] = "#{name}.png"
      row["__figure"] = problem.figure
    end
    row
  end

  # Writes one problem file per area, the figure SVGs into the build directory,
  # and a manifest the rasterizer reads.
  def write(rows, out_dir:, svg_dir:, manifest:, header:)
    FileUtils.mkdir_p(out_dir)
    FileUtils.rm_rf(svg_dir)
    FileUtils.mkdir_p(svg_dir)
    figures = []

    rows.each do |area, problems|
      cleaned = problems.map do |row|
        figure = row.delete("__figure")
        if figure
          svg_path = File.join(svg_dir, "#{File.basename(row['image'], '.png')}.svg")
          File.write(svg_path, figure.markup)
          figures << [ svg_path, row["image"], figure.width, figure.height ]
        end
        row
      end

      path = File.join(out_dir, "#{area}.yml")
      body = { "problems" => cleaned.sort_by { |row| [ row["topic"], row["elo"], row["text"] ] } }
      File.write(path, "#{header.call(area, cleaned)}---\n#{body.to_yaml(line_width: -1).delete_prefix("---\n")}")
    end

    FileUtils.mkdir_p(File.dirname(manifest))
    File.write(manifest, figures.map { |row| "#{row.join("\t")}\n" }.join)
    figures.size
  end
end
