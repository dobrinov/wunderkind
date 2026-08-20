# Numeric equivalence for exact-value answers: 3/4 ≡ 0,75 ≡ 0.75 ≡ 75%.
# Bulgarian students type decimal commas, so both separators parse.
module ExactValue
  module_function

  def parse(input)
    normalized = input.to_s.strip.tr(",", ".").gsub(/\s+/, " ")
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
    given_value = parse(given)

    if expected_value && given_value
      if tolerance.to_f.positive?
        (expected_value - given_value).abs.to_f <= tolerance.to_f
      else
        expected_value == given_value
      end
    else
      normalize_text(expected) == normalize_text(given)
    end
  end

  def normalize_text(input)
    input.to_s.strip.downcase.gsub(/\s+/, " ")
  end
end
