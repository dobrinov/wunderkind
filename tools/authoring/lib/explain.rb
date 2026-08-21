# Builds the worked solutions.
#
# Every explanation follows the same shape, because a student who has just got
# something wrong should not also have to work out how this particular author
# likes to write:
#
#   Идея:      the method, in one sentence — what kind of problem this is
#   1) 2) 3)   the steps, with the arithmetic actually carried out
#   Отговор:   the answer, with its unit
#   Проверка:  how to check it, done on the numbers of this problem
#   Внимание:  the mistake this problem is designed to catch (optional)
#
# The student sees the explanation when the answer was wrong, so "Внимание"
# earns its place: it names the wrong turn instead of only showing the right one.
module Explain
  module_function

  def build(idea:, steps: [], answer: nil, check: nil, watch: nil)
    lines = [ "Идея: #{idea}" ]
    Array(steps).compact.each_with_index { |step, index| lines << "#{index + 1}) #{step}" }
    lines << "Отговор: #{answer}" if answer
    lines << "Проверка: #{check}" if check
    lines << "Внимание: #{watch}" if watch
    lines.join("\n")
  end

  # Free-form, for the rare family whose solution is a short argument rather
  # than a calculation.
  def lines(*parts) = parts.compact.join("\n")
end
