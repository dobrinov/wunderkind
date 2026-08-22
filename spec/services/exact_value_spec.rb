require "rails_helper"

describe ExactValue do
  describe ".parse" do
    it "parses integers, decimals, and negative numbers" do
      ExactValue.parse("42").should eq(42)
      ExactValue.parse("-3.5").should eq(Rational(-7, 2))
    end

    it "parses Bulgarian decimal commas" do
      ExactValue.parse("0,75").should eq(Rational(3, 4))
    end

    it "parses fractions and mixed numbers" do
      ExactValue.parse("3/4").should eq(Rational(3, 4))
      ExactValue.parse("1 1/2").should eq(Rational(3, 2))
      ExactValue.parse("-1 1/2").should eq(Rational(-3, 2))
    end

    # What the MathLive keyboard's fraction key actually sends.
    it "parses a fraction whose parts arrive parenthesized" do
      ExactValue.parse("(1)/(2)").should eq(Rational(1, 2))
      ExactValue.parse("(12)/(5)").should eq(Rational(12, 5))
      ExactValue.parse("1(1)/(2)").should eq(Rational(3, 2))
      ExactValue.parse("-(3)/(4)").should eq(Rational(-3, 4))
      ExactValue.parse("(-3)/(4)").should eq(Rational(-3, 4))
    end

    it "parses percentages" do
      ExactValue.parse("75%").should eq(Rational(3, 4))
    end

    it "returns nil for non-numeric input and division by zero" do
      ExactValue.parse("abc").should be_nil
      ExactValue.parse("1/0").should be_nil
      ExactValue.parse("").should be_nil
    end
  end

  describe ".equivalent?" do
    it "treats equivalent numeric forms as equal" do
      ExactValue.equivalent?("3/4", "0,75").should be(true)
      ExactValue.equivalent?("3/4", "75%").should be(true)
      ExactValue.equivalent?("0.5", "1/2").should be(true)
    end

    it "accepts the fraction key's own notation for a typed fraction" do
      ExactValue.equivalent?("1/2", "(1)/(2)").should be(true)
      ExactValue.equivalent?("1 1/2", "1(1)/(2)").should be(true)
      ExactValue.equivalent?("0,5", "(1)/(2)").should be(true)
    end

    it "rejects different values" do
      ExactValue.equivalent?("3/4", "0.7").should be(false)
    end

    it "honors tolerance" do
      ExactValue.equivalent?("3.14", "3.1", tolerance: 0.05).should be(true)
      ExactValue.equivalent?("3.14", "3.0", tolerance: 0.05).should be(false)
    end

    it "falls back to case- and whitespace-insensitive text comparison" do
      ExactValue.equivalent?("Питагор", " питагор ").should be(true)
      ExactValue.equivalent?("Питагор", "Евклид").should be(false)
    end
  end
end
