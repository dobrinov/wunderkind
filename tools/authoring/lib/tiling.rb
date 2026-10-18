# Whether a board can be covered by 1×2 dominoes, decided by trying — not by
# a parity rule. The family that asks this used a rule ("an even number of
# cells is enough") and taught the mutilated chessboard backwards for 61
# problems; a search cannot make that mistake, and boards here are at most 6×6.
module Tiling
  # Which corners a board is missing, by name, so the text and the search
  # cannot describe two different boards.
  CORNER_KINDS = %i[none one opposite long_side short_side].freeze

  # How each kind reads after "4 на 6" in a problem. check.rb parses these back,
  # so the wording lives here once.
  CORNER_LABELS = {
    none: "",
    one: " без едно ъглово поле",
    opposite: " без две срещуположни ъглови полета",
    long_side: " без двете ъглови полета на една от дългите страни",
    short_side: " без двете ъглови полета на една от късите страни"
  }.freeze

  module_function

  def label(rows, cols, kind) = "#{rows} на #{cols}#{CORNER_LABELS.fetch(kind)}"

  # [rows, cols, kind] from a label, or nil if it is not one of ours.
  def parse(label)
    match = label.match(/\A(\d+) на (\d+)(.*)\z/)
    return nil unless match

    kind = CORNER_LABELS.key(match[3])
    kind && [ match[1].to_i, match[2].to_i, kind ]
  end

  def corners(rows, cols, kind)
    first = [ 0, 0 ]
    case kind
    when :none then []
    when :one then [ first ]
    when :opposite then [ first, [ rows - 1, cols - 1 ] ]
    # A side of length `cols` is a row; the long side is whichever is longer.
    when :long_side then cols >= rows ? [ first, [ 0, cols - 1 ] ] : [ first, [ rows - 1, 0 ] ]
    when :short_side then cols < rows ? [ first, [ 0, cols - 1 ] ] : [ first, [ rows - 1, 0 ] ]
    else raise ArgumentError, "unknown corner kind #{kind}"
    end
  end

  def tileable?(rows, cols, removed)
    free = Array.new(rows) { Array.new(cols, true) }
    removed.each { |r, c| free[r][c] = false }
    return false if free.flatten.count(true).odd?

    fill(free, rows, cols)
  end

  # Always cover the first free cell (row-major): it can only pair right or
  # down, which keeps the search tiny.
  def fill(free, rows, cols)
    index = free.flatten.index(true)
    return true if index.nil?

    r, c = index.divmod(cols)
    free[r][c] = false
    [ [ r, c + 1 ], [ r + 1, c ] ].each do |nr, nc|
      next unless nr < rows && nc < cols && free[nr][nc]

      free[nr][nc] = false
      return true if fill(free, rows, cols)

      free[nr][nc] = true
    end
    free[r][c] = true
    false
  end
end
