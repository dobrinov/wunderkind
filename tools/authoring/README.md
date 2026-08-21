# Authoring the question bank

The app has no question generator in it — questions are authored outside it and
imported. This directory is where the shipped **ladder corpus** is written:
`db/seeds/ladders/*.yml`, 22.7k problems with worked explanations (12.7k of them
interactive), plus the figure PNGs in `db/seeds/images/`.

**`PROBLEM_TYPES.md` next to this file is the catalogue**: every problem type in
the bank, what it is for, and the recipe for adding more of it. Read that when
you want new content; read this when you want to know how the tool works.

## The idea: families and rungs

A **family** is one *type* of problem — "find the third angle of a triangle",
"percent of an amount", "solve ax + b = c". Each family is written once, as a
block that takes a rung (a difficulty) and returns a problem. The builder asks
it for a handful of variants at each of six rising Elo ratings.

That is what makes the bank teachable rather than merely large. The dispatcher
aims about 147 points below the student, so a student who keeps missing a type
of problem drifts *down its ladder* until they meet the rung they can do, and
climbs back up the same type as their rating recovers. For that to work the
rungs have to be close together (60–150 points) and cover a wide span, which is
what `rungs:` declares — and what `spec/services/ladder_corpus_spec.rb` checks.

## Layout

    build.rb                 entry point: writes the problem files and figure SVGs
    check.rb                 validates the generated files before they are imported
    rasterize.sh             turns the figure SVGs into the PNGs the app serves
    lib/authoring.rb         the family DSL, deterministic variant generation, YAML output
    lib/num.rb               Bulgarian number formatting (decimal comma, U+2212 minus, fractions)
    lib/explain.rb           the shape of a worked solution
    lib/svg.rb               a small drawing surface
    lib/figures.rb           named figures: triangles, charts, solids, number lines, ...
    lib/widget_kit.rb        builders for the twelve interactive widgets
    families/*.rb            the content, one file per area

## Building

    ruby tools/authoring/build.rb           # everything (about 20 seconds)
    ruby tools/authoring/build.rb percent   # only families whose name starts with "percent"
    tools/authoring/rasterize.sh            # SVG -> PNG, needs headless Chrome (~45 s)
    ruby tools/authoring/check.rb           # validate
    bin/rails problems:import FILE=db/seeds/ladders

Generation is deterministic: variant parameters come from a `Random` seeded with
the family name, the rung and the attempt number, so a rebuild produces
byte-identical files and a re-import updates rather than duplicates.

`build.rb` reads `tmp/authoring/existing.txt` if it is there — a dump of the
question texts already in the bank — and skips anything that would collide with
them (the importer keys questions by their text, so a repeat would overwrite an
older authored question rather than add a new one). Refresh it with:

    bin/rails runner 'File.write("tmp/authoring/existing.txt", Question.pluck(:body_text).map { |t| t.tr("\n", " ") }.join("\n"))'

## Writing a family

```ruby
Authoring.family "percent.of_amount", topic: "Проценти", area: "fractions",
                 rungs: [ 970, 1060, 1150, 1240, 1330, 1430 ] do |c|
  pct = c.pick(c.by_level([ [ 10, 50 ], [ 10, 20, 25, 50 ], ... ]))
  base = c.int(c.by_level([ 2..12, 2..20, ... ]))
  ...
  c.q(text: "...", answer: Num.ans(result), explanation: Explain.build(...))
end
```

* `c.by_level([...])` picks the entry for this rung — that is how difficulty
  rises. `c.int`, `c.pick`, `c.sample`, `c.coin`, `c.person`, `c.thing`,
  `c.goods` draw the rest, all from the seeded RNG.
* `raise Authoring::Duplicate` rejects an attempt (bad parameters, or a number
  the family should not ask about). The builder just tries again.
* Answers must be numbers `ExactValue` can parse. Symbolic or verbal answers go
  through `options:` (multiple choice) instead — a typed "(x+3)(x−2)" would be
  compared as a string. Rounded answers (anything computed with π) pass
  `tolerance:`.
* `widget:` takes a hash from `WidgetKit` (`blanks`, `multi_select`, `grid_fill`,
  `grid_shade`, `plot`, `categorize`, `matcher`, `ordering`, `number_line`,
  `angle_dial`, `clock`, `fraction_bars`). The stem must name whatever the widget
  shows — the options, the items, the values — because the importer keys
  questions by their text and a fixed stem collapses a family into one problem.
* `figure:` takes an `Svg::Figure` from `Figures`; the builder writes the SVG,
  the rasterizer makes the PNG, and the row points at it. Put every number from
  the figure into the question text too: the views render question images with
  an empty `alt`.
* `hints:` is the ladder the student can reveal before answering, 2-3 rungs,
  cheapest nudge first and **never the answer** — `check.rb` refuses a rung
  that states it. It is not the explanation cut short: an explanation is read
  after a wrong answer, a hint instead of giving up. Imported ladders go live
  without review, like the explanations beside them.
* Explanations use `Explain.build(idea:, steps:, answer:, check:, watch:)`. The
  student sees them only after a wrong answer, so `watch:` — the mistake this
  problem is designed to catch — is the most valuable line in it.

## Provenance

Everything here is written for this app. The Bulgarian curriculum sequence (the
grade tracks on Khan Academy BG) and IXL's skill lists were read for coverage
and difficulty order only; no problem text comes from either.
