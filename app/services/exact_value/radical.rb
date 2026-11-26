# An exact number with square roots in it — 7√3/3, 2√5 − 2, √12 — for the
# answers of 10th- to 12th-grade geometry, where a side or an area is
# irrational and a rounded decimal is not what the key prints. Held as a sum of
# rational multiples of square roots of square-free integers ({3 => 7/3} is
# 7√3/3), so √12 and 2√3, or 7√3/3 and 7/√3, are the same value. A value with
# no root left in it is handed back as the plain Rational it is.
module ExactValue
  class Radical
    attr_reader :terms

    def self.of(rational) = new(1 => Rational(rational))

    def self.root(radicand)
      radicand = Rational(radicand)
      raise ArgumentError, "negative radicand" if radicand.negative?

      # √(p/q) = √(pq)/q, then pull the square factors out.
      n = radicand.numerator * radicand.denominator
      outside = 1
      factor = 2
      while factor * factor <= n
        while (n % (factor * factor)).zero?
          n /= factor * factor
          outside *= factor
        end
        factor += 1
      end
      new(n => Rational(outside, radicand.denominator))
    end

    def initialize(terms)
      @terms = terms.reject { |_, c| c.zero? }.transform_values { Rational(_1) }.freeze
    end

    def +(other) = Radical.new(terms.merge(other.terms) { |_, a, b| a + b })
    def -(other) = self + other * Radical.of(-1)
    def -@ = self * Radical.of(-1)

    def *(other)
      product = Hash.new(Rational(0))
      terms.each do |n, a|
        other.terms.each do |m, b|
          root = Radical.root(n * m)
          root.terms.each { |k, c| product[k] += a * b * c }
        end
      end
      Radical.new(product)
    end

    # Division by a single term (a rational, or c√m): multiply by its inverse.
    # A sum in the denominator (1/(√2 + 1)) is not an answer anyone types.
    def /(other)
      raise ZeroDivisionError if other.terms.empty?
      raise ArgumentError, "divisor is a sum" if other.terms.size > 1

      m, c = other.terms.first
      self * Radical.new(m => Rational(1, c * m))
    end

    def rational? = terms.keys.all? { _1 == 1 }
    def to_r = terms.fetch(1, Rational(0))
    def to_f = terms.sum { |n, c| c.to_f * Math.sqrt(n) }

    # The plain Rational when no root is left; otherwise the radical itself.
    def simplest = rational? ? to_r : self

    def ==(other)
      case other
      when Radical then terms == other.terms
      when Numeric then rational? && to_r == other
      else false
      end
    end
    alias eql? ==
    def hash = terms.hash

    def inspect = "#<ExactValue::Radical #{terms.map { |n, c| n == 1 ? c.to_s : "#{c}√#{n}" }.join(' + ')}>"
  end
end
