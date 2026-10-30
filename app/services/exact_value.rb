# Numeric equivalence for exact-value answers: 3/4 ≡ 0,75 ≡ 0.75 ≡ 75%.
# Bulgarian students type decimal commas, so both separators parse.
module ExactValue
  module_function

  # MathLive serializes a fraction with both parts parenthesized: "(1)/(2)" for
  # a half, "1(1)/(2)" for one and a half, "-(3)/(4)" for minus three quarters.
  # A child who reached for the fraction key on the virtual keyboard typed no
  # parentheses and must not be marked wrong for the serializer's brackets.
  PARENTHESIZED_FRACTION = %r{\A(?<sign>[+-])?(?<whole>\d+)?\s*\(\s*(?<numerator>[+-]?\d+)\s*\)\s*/\s*\(\s*(?<denominator>\d+)\s*\)\z}

  def parse(input)
    normalized = unwrap_fraction(input.to_s.strip).tr(",", ".").gsub(/\s+/, " ")
    return nil if normalized.empty?

    percent = normalized.end_with?("%")
    normalized = normalized.delete_suffix("%").strip if percent

    value =
      case normalized
      when %r{\A([+-]?\d+) (\d+)/(\d+)\z} # mixed number: 1 1/2
        sign = Regexp.last_match(1).to_i.negative? ? -1 : 1
        Regexp.last_match(1).to_i + sign * Rational(Regexp.last_match(2).to_i, Regexp.last_match(3).to_i)
      when %r{\A([+-]?\d+)/(\d+)\z}
        Rational(Regexp.last_match(1).to_i, Regexp.last_match(2).to_i)
      when /\A[+-]?\d+(\.\d+)?\z/
        Rational(normalized)
      end

    return nil if value.nil?

    percent ? value / 100 : value
  rescue ZeroDivisionError
    nil
  end

  def equivalent?(expected, given, tolerance: nil)
    expected_value = parse(expected)
    return normalize_text(expected) == normalize_text(given) if expected_value.nil?

    readings(given).any? do |given_value|
      if tolerance.to_f.positive?
        (expected_value - given_value).abs.to_f <= tolerance.to_f
      else
        expected_value == given_value
      end
    end
  end

  # What a child typed, read the way a teacher would. `parse` stays strict,
  # because it also decides what a stored answer and a suggested problem are
  # allowed to be; this is only ever the answer side. The family field test
  # (2026-10-30) found about one "wrong" answer in six was right, written the
  # way school writes it:
  #   "5 152"      a space between thousands, as Bulgarian schools teach
  #   "x = 72"     the variable the equation asked for
  #   "43°", "8 евро", "34 m/s", "с 14"   the unit, or a word, around the number
  #   "8!"         a factorial, in a counting problem
  # Each is accepted only when there is exactly one number in what was typed,
  # so "3 4" or "12 и 5" are never read as anything.
  #
  # A percent answer can mean either thing: "40%" to „колко процента е 2/5" is
  # 40, to „колко е 2/5 като дроб" it is 0,4. Both readings are offered and
  # the grader takes the one that matches.
  def readings(input)
    percent = input.to_s.match?(/\d\s*%/)
    if (value = parse(input))
      # parse has already divided a percent by 100.
      percent ? [ value, value * 100 ].uniq : [ value ]
    elsif (number = lenient(input.to_s))
      # lenient read the number without its sign.
      percent ? [ number / 100, number ].uniq : [ number ]
    else
      []
    end
  end

  THOUSANDS = /(?<=\d)[ \u00a0\u202f](?=\d{3}(?!\d))/
  NUMBER = %r{[+-]?\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?}
  FACTORIAL = /\A\s*(\d{1,2})\s*!\s*\z/

  def lenient(input)
    text = input.tr("−–", "--").strip
    return (1..Regexp.last_match(1).to_i).reduce(1, :*) if text.match(FACTORIAL)

    text = text.gsub(THOUSANDS, "")
    numbers = text.scan(%r{\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?}).size
    mixed = text.match(%r{[+-]?\d+ \d+/\d+})
    return parse(mixed[0]) if mixed && text.sub(mixed[0], "").match?(/\A[^\d]*\z/)
    return nil unless numbers == 1

    number = text[NUMBER]
    parse(number.delete("+").sub(/\A-\s*/, "-"))
  end

  def unwrap_fraction(input)
    match = PARENTHESIZED_FRACTION.match(input)
    return input if match.nil?

    fraction = "#{match[:numerator]}/#{match[:denominator]}"
    match[:whole] ? "#{match[:sign]}#{match[:whole]} #{fraction}" : "#{match[:sign]}#{fraction}"
  end

  def normalize_text(input)
    input.to_s.strip.downcase.gsub(/\s+/, " ")
  end
end
