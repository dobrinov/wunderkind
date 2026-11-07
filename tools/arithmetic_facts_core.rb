# Writes db/seeds/arithmetic_facts_core.yml: the drill set production imports,
# chosen from the full fact tables in db/seeds/arithmetic_facts.yml.
#
#   ruby tools/arithmetic_facts_core.rb
#
# The full file is every pair, so 7,000 of its 7,646 rows are two-digit sums
# and differences that practise the same handful of skills, and all of them
# are rated 663-920, the easy end where the bank holds about 1,500 other
# problems. Imported whole, they would make most of what a young child is
# offered a bare sum, and 39 students could never answer each of them often
# enough to calibrate its rating. The core keeps every fact a first- or
# second-grader must know by heart and a fixed sample of each two-digit skill.
# Rows are copied verbatim (text, topic, answer, elo), so the importer and
# `rake questions:taught_from` treat them exactly as they would the full file.
require "yaml"

ROOT = File.expand_path("..", __dir__)
SOURCE = File.join(ROOT, "db/seeds/arithmetic_facts.yml")
TARGET = File.join(ROOT, "db/seeds/arithmetic_facts_core.yml")
PER_SKILL = 50
FACT = /\AКолко е (\d+) ([+−\-×·:]) (\d+)\?\z/

rows = YAML.safe_load_file(SOURCE).fetch("problems")

def skill(op, a, b)
  case op
  when "×", "·", ":" then :table
  when "+"
    return :bond if a + b <= 20
    return :tens if (a % 10).zero? && (b % 10).zero?
    small, large = [ a, b ].minmax
    carry = (small % 10) + (large % 10) >= 10
    kind = small < 10 ? "one" : "two"
    :"add_#{kind}_#{carry ? 'carry' : 'plain'}"
  else
    return :bond if a <= 20
    return :tens if (a % 10).zero? && (b % 10).zero?
    borrow = (b % 10) > (a % 10)
    kind = b < 10 ? "one" : "two"
    :"sub_#{kind}_#{borrow ? 'borrow' : 'plain'}"
  end
end

groups = rows.group_by do |row|
  match = FACT.match(row["text"]) or raise "not a fact: #{row['text']}"
  skill(match[2], match[1].to_i, match[3].to_i)
end

# Every bond, table and tens fact; from each two-digit skill, PER_SKILL rows spaced
# evenly through the skill sorted by rating, so the sample spans the skill's
# easy and hard ends instead of its first few numbers.
picked = groups.flat_map do |name, members|
  next members if %i[bond table tens].include?(name)

  sorted = members.sort_by { |row| [ row["elo"], row["text"] ] }
  next sorted if sorted.size <= PER_SKILL

  step = sorted.size.fdiv(PER_SKILL)
  Array.new(PER_SKILL) { |index| sorted[(index * step).floor] }
end

picked.sort_by! { |row| rows.index(row) }

counts = groups.keys.sort.map { |name| "#   #{name.to_s.ljust(20)} #{picked.count { |row| groups[name].include?(row) }} of #{groups[name].size}" }

header = [
  "# The arithmetic drill production imports: #{picked.size} facts chosen from the",
  "# full tables in db/seeds/arithmetic_facts.yml by tools/arithmetic_facts_core.rb.",
  "# Do not edit by hand; change the script and run it again.",
  "#",
  "# Every sum and difference within 20, the whole 10x10 times table and its",
  "# division facts, every tens-and-tens fact, and #{PER_SKILL} rows of each other",
  "# two-digit skill (with or without crossing a ten, one- or two-digit second",
  "# number) spaced evenly across that skill's ratings. Rows are copied verbatim",
  "# from the full file, so importing the full file later only adds the rest.",
  "#",
  *counts,
  "#",
  "#   bin/rails problems:import FILE=db/seeds/arithmetic_facts_core.yml",
  ""
].join("\n")

File.write(TARGET, header + { "problems" => picked }.to_yaml)
puts "#{picked.size} facts → #{TARGET}"
