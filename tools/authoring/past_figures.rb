#!/usr/bin/env ruby
# Draws the `figure:` of past-paper problems and ours on their model
# (db/seeds/past, see PastPapers) with the corpus's figure library, so every
# drawn figure in the bank speaks one figure language.
#
#   ruby tools/authoring/past_figures.rb           # writes SVGs + manifest
#   tools/authoring/rasterize.sh tmp/authoring/past-manifest.tsv
#
# A `figure:` names a Figures function and its arguments:
#
#   figure:
#     kind: balances
#     scales:
#     - left: [{shape: square}, {shape: circle}]
#       right: ["33 г"]
#
# The PNG lands beside the paper's scans as fig-<year>-<task>[-<level>].png,
# which is the name PastPapers attaches when a problem has a figure and no
# image of its own.
require "yaml"
require "fileutils"
require_relative "lib/figures"

ROOT = File.expand_path("../..", __dir__)
PAST = File.join(ROOT, "db/seeds/past")
SVG_DIR = File.join(ROOT, "tmp/authoring/past-svg")
MANIFEST = File.join(ROOT, "tmp/authoring/past-manifest.tsv")

def symbolize(value)
  case value
  when Hash then value.to_h { |k, v| [ k.to_sym, symbolize(v) ] }
  when Array then value.map { |v| symbolize(v) }
  else value
  end
end

def figure_name(year, number, level = nil) = [ "fig", year, number, level ].compact.join("-")

rows = []
Dir[File.join(PAST, "**/*.yml")].sort.each do |path|
  slug, grade, file = path.delete_prefix("#{PAST}/").delete_suffix(".yml").split("/")
  year = file.delete_suffix("-modelled")
  data = YAML.safe_load_file(path)
  problems = data.is_a?(Hash) ? data["problems"] : data
  problems.each do |problem|
    next unless problem["figure"]

    spec = symbolize(problem["figure"])
    kind = spec.delete(:kind) or abort "#{path}: figure without kind"
    number = (problem.dig("source", "number") || problem["modelled_on"]).to_s
    name = figure_name(year, number, problem["level"])
    figure = Figures.public_send(kind, **spec)
    FileUtils.mkdir_p(SVG_DIR)
    svg = File.join(SVG_DIR, "#{slug}-#{grade}-#{name}.svg")
    File.write(svg, figure.markup)
    rows << [ svg, File.join(ROOT, "db/seeds/images/past", slug, grade, "#{name}.png"), figure.width, figure.height ]
  end
end
FileUtils.mkdir_p(File.dirname(MANIFEST))
File.write(MANIFEST, rows.map { |row| "#{row.join("\t")}\n" }.join)
puts "#{rows.size} figures → #{MANIFEST}"
