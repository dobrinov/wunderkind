module ExactValue
  # Reads a value with square roots: numbers (decimal comma or point), √ before
  # a number or a bracket, brackets, + − · * / and a product written without a
  # sign before a root or a bracket („7√3“, „2(√5 − 1)“, „(3/2)√5“). Anything
  # else is not a value, and the result is nil.
  class RadicalParser
    TOKEN = %r{\s*(?:(\d+(?:[.,]\d+)?)|(√|sqrt)|([-+*/·()]))}

    def self.parse(input)
      new(input).parse
    end

    def initialize(input)
      @tokens = []
      text = input.to_s.tr("−–×", "\\-\\-*").strip
      position = 0
      while position < text.length
        match = TOKEN.match(text, position)
        return @tokens = nil if match.nil? || match.begin(0) != position

        @tokens << (match[1] ? [ :number, Rational(match[1].tr(",", ".")) ] : match[2] ? [ :root ] : [ match[3].tr("·", "*").to_sym ])
        position = match.end(0)
        position += 1 while text[position] == " "
      end
    end

    def parse
      return nil if @tokens.nil? || @tokens.empty?

      @at = 0
      value = expression
      return nil unless @at == @tokens.size

      value.simplest
    rescue ArgumentError, ZeroDivisionError, NoMethodError
      nil
    end

    private

    def peek = @tokens[@at]&.first

    def take
      token = @tokens[@at]
      @at += 1
      token
    end

    def expression
      value = term
      while %i[+ -].include?(peek)
        operator = take.first
        value = operator == :+ ? value + term : value - term
      end
      value
    end

    # Products and quotients, left to right; a root or a bracket straight
    # after a factor multiplies it.
    def term
      value = signed
      loop do
        case peek
        when :*  then take; value *= signed
        when :/  then take; value /= signed
        when :root, :"(" then value *= primary
        else return value
        end
      end
    end

    def signed
      case peek
      when :- then take; -signed
      when :+ then take; signed
      else primary
      end
    end

    def primary
      token = take or raise ArgumentError, "value ends early"
      case token.first
      when :number then Radical.of(token.last)
      when :root
        inner = peek == :"(" ? primary : (take_number or raise ArgumentError, "√ needs a number")
        raise ArgumentError, "a root inside a root" unless inner.rational?

        Radical.root(inner.to_r)
      when :"("
        value = expression
        raise ArgumentError, "unclosed bracket" unless take&.first == :")"

        value
      else raise ArgumentError, "unexpected #{token.first}"
      end
    end

    def take_number
      return nil unless peek == :number

      Radical.of(take.last)
    end
  end
end
