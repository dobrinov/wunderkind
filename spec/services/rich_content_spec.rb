require "rails_helper"

describe RichContent do
  let(:doc) do
    {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "Колко е " },
            { "type" => "text", "text" => "половината", "marks" => [ { "type" => "bold" } ] },
            { "type" => "math", "attrs" => { "latex" => "x^2" } }
          ]
        }
      ]
    }
  end

  it "renders paragraphs, marks, and math spans" do
    html = RichContent.render(doc)

    html.should include("<p>Колко е <strong>половината</strong>")
    html.should include('data-controller="math"')
    html.should include("data-math-latex-value")
  end

  # The same stacked fraction the options and the widgets show, so a card never
  # carries two notations for one value.
  it "sets a plain fraction with .frac rather than KaTeX" do
    html = RichContent.render(RichContent.text_to_doc("Сравни 1/2 и x^2"))

    html.should include('<span class="frac"><span>1</span><span>2</span></span>')
    html.should_not include("data-math-latex-value=\"\\frac")
  end

  it "escapes HTML in text and latex" do
    xss = { "type" => "doc", "content" => [ { "type" => "paragraph", "content" => [ { "type" => "text", "text" => "<script>x</script>" } ] } ] }

    RichContent.render(xss).should_not include("<script>")
  end

  it "ignores unknown node types" do
    weird = { "type" => "doc", "content" => [ { "type" => "iframe", "attrs" => { "src" => "evil" } } ] }

    RichContent.render(weird).should eq("")
  end

  it "projects plain text, reading a fraction back the way a problem file writes it" do
    RichContent.plain_text(doc).should eq("Колко е половинатаx^2")
    RichContent.plain_text(RichContent.text_to_doc("Колко е 1/2?")).should eq("Колко е 1/2?")
  end

  it "round-trips plain text into a document" do
    doc = RichContent.text_to_doc("първи ред\nвтори ред")

    RichContent.plain_text(doc).should eq("първи ред\nвтори ред")
  end

  it "promotes a fraction written in plain text to a math node" do
    doc = RichContent.text_to_doc("Колко е 1/2 от 12?")

    doc.dig("content", 0, "content").should eq([
      { "type" => "text", "text" => "Колко е " },
      { "type" => "math", "attrs" => { "latex" => "\\frac{1}{2}" } },
      { "type" => "text", "text" => " от 12?" }
    ])
  end

  it "leaves alone what is not a fraction" do
    [ "Скорост 60 km/h", "0,5/2", "1/2/3", "12 + 5" ].each do |text|
      nodes = RichContent.text_to_doc(text).dig("content", 0, "content")

      nodes.map { |node| node["type"] }.should eq([ "text" ])
    end
  end

  it "takes a longer denominator whole" do
    nodes = RichContent.text_to_doc("1/25").dig("content", 0, "content")

    nodes.should eq([ { "type" => "math", "attrs" => { "latex" => "\\frac{1}{25}" } } ])
  end

  # body_text is what the importer dedupes on and what an export writes back to
  # the problem file, so promoting a fraction must not move it.
  it "keeps the plain-text projection identical to the source text" do
    [ "Сравни 1/2 и 3/4.", "Ани изяде 1/2, а Бони 1/3.", "Смесено число 1 1/2", "Няма дроб: 12 + 5" ].each do |text|
      RichContent.plain_text(RichContent.text_to_doc(text)).should eq(text)
    end
  end
end
