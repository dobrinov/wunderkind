# Whether a grid puzzle has exactly one completion. A widget grades against one
# stored answer, so a puzzle with two completions marks one of them wrong — and
# a generator that hides cells at random will, now and then, hide one too many.
#
# Both the families (which raise Authoring::Duplicate on a puzzle that fails)
# and check.rb (which re-tests every row of the built files) ask here.
module Uniqueness
  module_function

  # Puzzles made of sums — a magic square, an addition pyramid. Each equation is
  # [{ cell => coefficient }, constant]: the cells times their coefficients add
  # up to the constant. Known cells are substituted from `known`; the puzzle is
  # determined when the equations left over the unknown cells have full rank.
  def linear?(unknowns, equations, known)
    matrix = equations.map do |terms, constant|
      row = Array.new(unknowns.size, 0r)
      rest = Rational(constant)
      terms.each do |cell, coefficient|
        if (index = unknowns.index(cell))
          row[index] += coefficient
        else
          rest -= coefficient * Rational(known.fetch(cell))
        end
      end
      row + [ rest ]
    end

    rank(matrix, unknowns.size) == unknowns.size
  end

  def rank(matrix, columns)
    rows = matrix.map(&:dup)
    rank = 0
    columns.times do |column|
      pivot = (rank...rows.size).find { |r| !rows[r][column].zero? }
      next unless pivot

      rows[rank], rows[pivot] = rows[pivot], rows[rank]
      rows.each_index do |r|
        next if r == rank || rows[r][column].zero?

        factor = rows[r][column] / rows[rank][column]
        rows[r] = rows[r].zip(rows[rank]).map { |a, b| a - (factor * b) }
      end
      rank += 1
    end
    rank
  end

  # The equations of a 3×3 magic square with this constant.
  def magic_square(constant)
    lines = (0..2).map { |r| (0..2).map { |c| [ r, c ] } } +
            (0..2).map { |c| (0..2).map { |r| [ r, c ] } } +
            [ (0..2).map { |i| [ i, i ] }, (0..2).map { |i| [ i, 2 - i ] } ]
    lines.map { |cells| [ cells.to_h { |cell| [ cell, 1 ] }, constant ] }
  end

  # An addition pyramid stored bottom row first: row r has 4 - r cells and each
  # is the sum of the two below it.
  def pyramid(height = 4)
    (1...height).flat_map do |r|
      (0...(height - r)).map { |c| [ { [ r, c ] => 1, [ r - 1, c ] => -1, [ r - 1, c + 1 ] => -1 }, 0 ] }
    end
  end

  # Latin-style grids: every row and every column holds each symbol once. Counts
  # completions of the nil cells, stopping at `limit`.
  def latin_completions(grid, symbols, limit: 2)
    blanks = grid.each_with_index.flat_map { |row, r| row.each_index.select { |c| row[c].nil? }.map { |c| [ r, c ] } }
    count = 0
    search = lambda do |index|
      return count += 1 if index == blanks.size

      r, c = blanks[index]
      symbols.each do |symbol|
        next if grid[r].include?(symbol) || grid.any? { |row| row[c] == symbol }

        grid[r][c] = symbol
        search.call(index + 1)
        grid[r][c] = nil
        return if count >= limit
      end
    end
    search.call(0)
    count
  end
end
