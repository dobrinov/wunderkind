# Number formatting and small number-theory helpers shared by every family.
#
# Two separate jobs, and they must not be confused:
#
#   Num.bg(x)  formats a number for *problem text* — Bulgarian typography:
#              decimal comma, U+2212 minus, fractions as "3/4".
#   Num.ans(x) formats a number for the *answer* field, which ExactValue has
#              to parse: ASCII hyphen for the minus (U+2212 falls through to a
#              string comparison and a correct answer would be marked wrong).
module Num
  module_function

  MINUS = "−" # typographic minus, for text only

  def rat(value)
    value.is_a?(Rational) ? value : Rational(value.to_s.tr(",", "."))
  end

  # Decimal with at most `places` digits, trailing zeros trimmed.
  def dec(value, places = 2, sep: ",")
    rounded = (rat(value) * 10**places).round / Rational(10**places)
    whole = rounded.truncate.abs
    frac_digits = ((rounded.abs - whole) * 10**places).round.to_s.rjust(places, "0").sub(/0+\z/, "")
    sign = rounded.negative? ? "-" : ""
    frac_digits.empty? ? "#{sign}#{whole}" : "#{sign}#{whole}#{sep}#{frac_digits}"
  end

  # True when the fraction terminates as a short decimal (denominator 2^a·5^b).
  def terminating?(value, places = 4)
    d = rat(value).denominator
    d /= 2 while (d % 2).zero?
    d /= 5 while (d % 5).zero?
    d == 1 && rat(value) == (rat(value) * 10**places).round / Rational(10**places)
  end

  # Problem-text form: whole numbers plain, everything else as a fraction.
  # Decimals are asked for explicitly with Num.dec — a family knows whether it
  # is teaching "3/4" or "0,75", and the two are different exercises.
  def bg(value)
    r = rat(value)
    return r.to_i.to_s.sub("-", MINUS) if r.denominator == 1

    frac(r)
  end

  # Answer-field form: same numbers, ASCII minus.
  def ans(value)
    return value.to_s if value.is_a?(String)

    r = rat(value)
    return r.to_i.to_s if r.denominator == 1
    return dec(r, 4) if terminating?(r)

    frac(r)
  end

  # "3/4" — reduced, sign in front, whole numbers collapse to an integer.
  def frac(numerator, denominator = nil)
    r = denominator ? Rational(numerator, denominator) : rat(numerator)
    return r.to_i.to_s if r.denominator == 1

    sign = r.negative? ? MINUS : ""
    "#{sign}#{r.numerator.abs}/#{r.denominator}"
  end

  # Mixed number, the form Bulgarian primary school asks for: 7/3 -> "2 1/3".
  def mixed(numerator, denominator = nil)
    r = denominator ? Rational(numerator, denominator) : rat(numerator)
    whole = r.abs.truncate
    rest = r.abs - whole
    sign = r.negative? ? MINUS : ""
    return "#{sign}#{whole}" if rest.zero?
    return "#{sign}#{rest.numerator}/#{rest.denominator}" if whole.zero?

    "#{sign}#{whole} #{rest.numerator}/#{rest.denominator}"
  end

  # Prices keep both stotinki: 12,50 лв., not 12,5 лв.
  def dec2(value)
    r = rat(value)
    return r.to_i.to_s if r.denominator == 1

    whole = r.abs.truncate
    cents = ((r.abs - whole) * 100).round
    "#{r.negative? ? '-' : ''}#{whole},#{cents.to_s.rjust(2, '0')}"
  end

  def money(value) = "#{dec2(value)} лв."

  # Counted forms. Bulgarian masculine nouns take a special counted plural
  # ("2 молива", not "2 моливи"), so every noun ships both forms.
  def noun(count, one, many)
    count.abs == 1 ? "#{count} #{one}" : "#{count} #{many}"
  end

  def gcd(a, b) = b.zero? ? a.abs : gcd(b, a % b)

  def lcm(a, b) = (a * b).abs / gcd(a, b)

  def prime?(n)
    return false if n < 2

    (2..Integer.sqrt(n)).none? { |d| (n % d).zero? }
  end

  def primes_upto(limit) = (2..limit).select { |n| prime?(n) }

  def divisors(n) = (1..n.abs).select { |d| (n % d).zero? }

  def factorize(n)
    factors = {}
    rest = n.abs
    d = 2
    while d * d <= rest
      while (rest % d).zero?
        factors[d] = factors.fetch(d, 0) + 1
        rest /= d
      end
      d += 1
    end
    factors[rest] = factors.fetch(rest, 0) + 1 if rest > 1
    factors
  end

  def factor_string(n)
    factorize(n).flat_map { |base, power| [ base.to_s ] * power }.join(" · ")
  end

  # Superscripts, so "x²" reads like the textbook instead of "x^2".
  # Letters too: an exponent is often a variable ("2ˣ"), and writing it as "2x"
  # turns a power into a product.
  SUPERSCRIPT = { "0" => "⁰", "1" => "¹", "2" => "²", "3" => "³", "4" => "⁴",
                  "5" => "⁵", "6" => "⁶", "7" => "⁷", "8" => "⁸", "9" => "⁹",
                  "-" => "⁻", "x" => "ˣ", "n" => "ⁿ", "a" => "ᵃ", "m" => "ᵐ",
                  "k" => "ᵏ", "t" => "ᵗ" }.freeze

  def sup(exponent) = exponent.to_s.chars.map { |c| SUPERSCRIPT.fetch(c, c) }.join

  SUBSCRIPT = { "0" => "₀", "1" => "₁", "2" => "₂", "3" => "₃", "4" => "₄",
                "5" => "₅", "6" => "₆", "7" => "₇", "8" => "₈", "9" => "₉" }.freeze

  # log₂, log₁₀ — the base of a logarithm, written the way print does it.
  def sub_digits(value) = value.to_s.chars.map { |c| SUBSCRIPT.fetch(c, c) }.join

  def power(base, exponent) = "#{base}#{sup(exponent)}"

  # Signed term for expressions: leading "+" dropped, minus spaced as in print.
  def term(coefficient, symbol = "x")
    return "" if coefficient.zero?

    coefficient.negative? ? "#{MINUS} #{monomial(coefficient.abs, symbol)}" : "+ #{monomial(coefficient.abs, symbol)}"
  end

  def lead(coefficient, symbol = "x")
    return "0" if coefficient.zero?

    coefficient.negative? ? "#{MINUS}#{monomial(coefficient.abs, symbol)}" : monomial(coefficient.abs, symbol)
  end

  # 1x is written x, but a bare constant keeps its 1.
  def monomial(magnitude, symbol)
    return bg(magnitude) if symbol.to_s.empty?

    magnitude == 1 ? symbol.to_s : "#{bg(magnitude)}#{symbol}"
  end

  # ax + b, printed the way a textbook prints it.
  def linear(a, b, symbol = "x")
    return bg(b) if a.zero?
    return lead(a, symbol) if b.zero?

    "#{lead(a, symbol)} #{term(b, '')}"
  end

  # ax² + bx + c
  def quadratic(a, b, c, symbol = "x")
    parts = [ lead(a, "#{symbol}#{sup(2)}") ]
    parts << term(b, symbol) unless b.zero?
    parts << term(c, "") unless c.zero?
    parts.join(" ")
  end

  def signed(value) = value.negative? ? "(#{MINUS}#{bg(value.abs)})" : bg(value)
end
