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
    [ "Скорост 60 km/h", "0,5/2", "1/2/3", "12 + 5", "cos α = √2/2" ].each do |text|
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

  describe "the authoring language" do
    # The one list both parsers are held to: this file runs it through
    # parse_authoring, and spec/javascript/rich_content_cases.mjs through the
    # editor's preview (app/javascript/lib/authoring.js).
    fixture = Rails.root.join("spec/fixtures/rich_content_cases.json")

    JSON.parse(fixture.read).each do |example|
      it "parses #{example['note']} (#{example['text'].inspect}#{', LaTeX on' if example['latex']})" do
        RichContent.parse_authoring(example["text"], latex: example["latex"]).should eq(example["doc"])
      end
    end

    it "is parsed the same way by the preview" do
      skip "node is not installed" unless system("node", "--version", out: File::NULL, err: File::NULL)

      output, status = Open3.capture2("node", Rails.root.join("spec/javascript/rich_content_cases.mjs").to_s,
                                      Rails.root.join("app/javascript/lib/authoring.js").to_s, fixture.to_s)

      status.should be_success
      JSON.parse(output).should eq([])
    end

    it "is the problem file's language when LaTeX is off" do
      text = "Ани изяде 1/2, а Бони 1/3.\nКолко остана?"

      RichContent.parse_authoring(text).should eq(RichContent.text_to_doc(text))
    end

    it "writes a fraction back as a/b and any other formula as $…$" do
      doc = { "type" => "doc", "content" => [
        { "type" => "paragraph", "content" => [
          { "type" => "text", "text" => "Корен " },
          { "type" => "math", "attrs" => { "latex" => "\\sqrt{x}" } },
          { "type" => "text", "text" => " и " },
          { "type" => "math", "attrs" => { "latex" => "\\frac{3}{4}" } },
          { "type" => "hardBreak" },
          { "type" => "text", "text" => "за $5", "marks" => [ { "type" => "bold" } ] }
        ] }
      ] }

      RichContent.authoring_text(doc).should eq("Корен $\\sqrt{x}$ и 3/4\nза \\$5")
    end

    # "1" straight before a stored fraction would read back as 11/2, and a
    # negative numerator as a minus sign before a half; both lines spell their
    # formulas out instead, so reopening a question never changes it.
    it "spells a fraction out where a/b would not parse back to it" do
      [ [ { "type" => "text", "text" => "1" }, { "type" => "math", "attrs" => { "latex" => "\\frac{1}{2}" } } ],
        [ { "type" => "math", "attrs" => { "latex" => "\\frac{-1}{2}" } } ] ].each do |nodes|
        doc = { "type" => "doc", "content" => [ { "type" => "paragraph", "content" => nodes } ] }

        RichContent.parse_authoring(RichContent.authoring_text(doc), latex: true).should eq(doc)
      end
    end

    # Every problem that ships, through the admin form and back: the document
    # must come out as it went in, and body_text — what the importer dedupes
    # on — must not move by a character.
    it "round-trips every shipped problem through the admin editor" do
      files = Dir[Rails.root.join("db/seeds/{ladders/,}*.yml")] - [ Rails.root.join("db/seeds/topics.yml").to_s ]
      texts = files.flat_map { |path| Array(YAML.safe_load_file(path)&.fetch("problems", nil)).map { |problem| problem["text"] } }
      texts.size.should be > 20_000

      mismatches = texts.reject do |text|
        doc = RichContent.text_to_doc(text)
        again = RichContent.parse_authoring(RichContent.authoring_text(doc), latex: true)
        again == doc && RichContent.plain_text(again) == RichContent.plain_text(doc)
      end

      mismatches.first(5).should eq([])
    end
  end

  describe ".valid?" do
    it "accepts what the parsers produce" do
      RichContent.valid?(RichContent.parse_authoring("Колко е 1/2?\n$x^2$", latex: true)).should be(true)
      RichContent.valid?({ "type" => "doc", "content" => [] }).should be(true)
    end

    it "accepts bold, italic and a hard break" do
      RichContent.valid?(doc).should be(true)
      RichContent.valid?({ "type" => "doc", "content" => [ { "type" => "paragraph", "content" => [
        { "type" => "text", "text" => "а", "marks" => [ { "type" => "italic" } ] }, { "type" => "hardBreak" }
      ] } ] }).should be(true)
    end

    it "refuses anything else" do
      paragraph = ->(*nodes) { { "type" => "doc", "content" => [ { "type" => "paragraph", "content" => nodes } ] } }

      [
        nil, "текст", [], { "type" => "doc" }, { "type" => "paragraph", "content" => [] },
        { "type" => "doc", "content" => [ { "type" => "heading", "content" => [] } ] },
        { "type" => "doc", "content" => [ { "type" => "text", "text" => "без абзац" } ] },
        paragraph.call({ "type" => "image", "attrs" => { "src" => "x" } }),
        paragraph.call({ "type" => "paragraph", "content" => [] }),
        paragraph.call({ "type" => "text", "text" => 5 }),
        paragraph.call({ "type" => "text", "text" => "а", "marks" => [ { "type" => "link" } ] }),
        paragraph.call({ "type" => "text", "text" => "а", "marks" => "bold" }),
        paragraph.call({ "type" => "math", "attrs" => { "latex" => [ "x" ] } }),
        paragraph.call({ "type" => "math" })
      ].each do |bad|
        RichContent.valid?(bad).should be(false), "accepted #{bad.inspect}"
      end
    end
  end
end
