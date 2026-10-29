# Renders the rich question documents (a restricted ProseMirror-style JSON tree)
# to HTML, and projects them to plain text for search and AI prompting.
#
# Supported nodes: doc, paragraph, text (bold/italic marks), math (inline LaTeX),
# hardBreak. Anything unknown is ignored, so a document can never inject markup.
module RichContent
  module_function

  def render(doc)
    return "" if doc.blank?

    render_nodes(Array(doc["content"])).html_safe
  end

  def plain_text(doc)
    return "" if doc.blank?

    Array(doc["content"]).map { |node| node_text(node) }.join("\n").strip
  end

  # A fraction as a problem file writes it: "3/4", "1/2 от 12". The bank is
  # authored as plain text, but "3/4" is not how a fraction is written in a
  # maths problem, so the text-to-document conversion promotes each one to a
  # math node and it is set over its bar like the textbook sets it. Guarded on
  # both sides so a decimal ("0,5/2") and a run of slashes ("1/2/3") are left as
  # they were typed, and so a longer number is taken whole ("1/25", not "1/2").
  # Not after a root sign either: "√2/2" is a root over two, and stacking the
  # "2/2" under the √ made it read as the root of a half.
  FRACTION = %r{(?<![\d,./√])(\d+)/(\d+)(?![\d/]|[.,]\d)}

  # The inverse, for the plain-text projection: body_text is what the importer
  # dedupes on and what an export writes back to the file, so a promoted
  # fraction has to read back exactly as the source text wrote it.
  LATEX_FRACTION = %r{\\frac\{(-?\d+)\}\{(\d+)\}}

  def text_to_doc(text)
    paragraphs = text.to_s.split(/\r?\n/).map do |line|
      { "type" => "paragraph", "content" => inline_nodes(line) }
    end
    { "type" => "doc", "content" => paragraphs }
  end

  def inline_nodes(line)
    return [] if line.blank?

    fraction_nodes(line)
  end

  def fraction_nodes(text)
    nodes = []
    remainder = text.to_s

    while (match = FRACTION.match(remainder))
      nodes << { "type" => "text", "text" => match.pre_match } unless match.pre_match.empty?
      nodes << { "type" => "math", "attrs" => { "latex" => "\\frac{#{match[1]}}{#{match[2]}}" } }
      remainder = match.post_match
    end

    nodes << { "type" => "text", "text" => remainder } unless remainder.empty?
    nodes
  end

  # --- The authoring language ---------------------------------------------------
  #
  # Problems are written in a plain <textarea> — on /suggestions by children
  # and parents, in the admin form by whoever runs the bank — and this is the
  # one parser both of them go through: a line is a paragraph and a bare "3/4"
  # is a fraction, exactly as text_to_doc reads a problem file, so a problem
  # typed into the app and the same problem imported from a file are the same
  # document. The admin form adds one escape, `$…$`, for the LaTeX the plain
  # text cannot say (a root over an expression, a power of a bracket), and
  # `\$` for a dollar that is just a dollar. Children are not offered it: the
  # symbol keys above their textarea cover what a school problem writes.
  #
  # app/javascript/lib/authoring.js is the same parser for the live preview,
  # and spec/fixtures/rich_content_cases.json is what holds the two together —
  # a preview that disagreed with the server would be showing the child a
  # problem that is not the one they are sending.
  LATEX_TOKEN = /\\\$|\$([^$\n]+)\$/

  def parse_authoring(text, latex: false)
    return text_to_doc(text) unless latex

    paragraphs = text.to_s.split(/\r?\n/).map do |line|
      { "type" => "paragraph", "content" => latex_inline_nodes(line) }
    end
    { "type" => "doc", "content" => paragraphs }
  end

  # Text between the `$…$` spans is promoted like any other line, span by
  # span, so a fraction never reaches across a formula.
  def latex_inline_nodes(line)
    return [] if line.blank?

    nodes = []
    buffer = +""
    remainder = line

    while (match = LATEX_TOKEN.match(remainder))
      buffer << match.pre_match
      if match[1]
        nodes.concat(fraction_nodes(buffer))
        buffer = +""
        nodes << { "type" => "math", "attrs" => { "latex" => match[1] } }
      else
        buffer << "$"
      end
      remainder = match.post_match
    end

    nodes.concat(fraction_nodes(buffer + remainder))
  end

  # A fraction the authoring text can write back as "a/b". Not a negative one:
  # FRACTION reads "-1/2" as a minus sign before a half, which is a different
  # document with the same text.
  AUTHORING_FRACTION = %r{\A\\frac\{(\d+)\}\{(\d+)\}\z}

  # The inverse of parse_authoring(text, latex: true), for reopening a stored
  # question in the admin form. Every line is written the way a person would
  # have typed it — a fraction as "3/4" — unless that spelling would not parse
  # back to the same document ("1" right before a fraction would make "11/2"),
  # in which case that line spells its formulas out as `$…$`. A hardBreak
  # becomes a new line, and bold and italic are dropped: the authoring
  # language has neither, and no question in the bank uses them.
  def authoring_text(doc)
    return "" if doc.blank?

    Array(doc["content"]).flat_map { |paragraph| authoring_lines(Array(paragraph["content"])) }.join("\n")
  end

  def authoring_lines(nodes)
    lines = [ [] ]
    nodes.each { |node| node["type"] == "hardBreak" ? lines << [] : lines.last << node }
    lines.map { |line| authoring_line(line) }
  end

  def authoring_line(nodes)
    compact = nodes.map { |node| authoring_piece(node, fractions: true) }.join
    spelled = nodes.map { |node| authoring_piece(node, fractions: false) }.join
    latex_inline_nodes(compact) == latex_inline_nodes(spelled) ? compact : spelled
  end

  def authoring_piece(node, fractions:)
    case node["type"]
    when "text" then node["text"].to_s.gsub("$", "\\$")
    when "math"
      latex = node.dig("attrs", "latex").to_s
      match = AUTHORING_FRACTION.match(latex) if fractions
      match ? "#{match[1]}/#{match[2]}" : "$#{latex}$"
    else ""
    end
  end

  # --- The schema ------------------------------------------------------------------
  #
  # The renderer already ignores what it does not know, so a bad document can
  # never inject markup; this is the stricter question of whether a document
  # is one at all, asked before one is stored. Only paragraphs at the top,
  # only text, math and hardBreak inside them, only bold and italic marks.
  INLINE_TYPES = %w[text math hardBreak].freeze
  MARK_TYPES = %w[bold italic].freeze

  def valid?(doc)
    doc.is_a?(Hash) && doc["type"] == "doc" && doc["content"].is_a?(Array) &&
      doc["content"].all? { |node| valid_paragraph?(node) }
  end

  def valid_paragraph?(node)
    node.is_a?(Hash) && node["type"] == "paragraph" &&
      (node["content"].nil? || (node["content"].is_a?(Array) && node["content"].all? { |child| valid_inline?(child) }))
  end

  def valid_inline?(node)
    return false unless node.is_a?(Hash) && INLINE_TYPES.include?(node["type"])

    case node["type"]
    when "text" then node["text"].is_a?(String) && valid_marks?(node["marks"])
    when "math" then node["attrs"].is_a?(Hash) && node["attrs"]["latex"].is_a?(String)
    else true
    end
  end

  def valid_marks?(marks)
    marks.nil? || (marks.is_a?(Array) && marks.all? { |mark| mark.is_a?(Hash) && MARK_TYPES.include?(mark["type"]) })
  end

  def render_nodes(nodes)
    nodes.map { |node| render_node(node) }.join
  end

  def render_node(node)
    case node["type"]
    when "paragraph"
      "<p>#{render_nodes(Array(node['content']))}</p>"
    when "text"
      wrap_marks(ERB::Util.html_escape(node["text"].to_s), Array(node["marks"]))
    when "math"
      render_math(node.dig("attrs", "latex").to_s)
    when "hardBreak"
      "<br>"
    else
      ""
    end
  end

  # A fraction of plain integers is set with .frac — the CSS stacked fraction —
  # and not handed to KaTeX. A question body and the multiple-choice options
  # under it show fractions inches apart, and the options are plain strings with
  # no document to put a math node in, so KaTeX in one and .frac in the other
  # would put two different fractions on one card. The same three spans are
  # written in shared/_frac (for those values) and in lib/frac.js (for widget
  # labels); this is the third place, and all any of them do is stack two
  # numbers. Everything else in a math node is real LaTeX and goes to KaTeX.
  SIMPLE_FRACTION = %r{\A\\frac\{(-?\d+)\}\{(\d+)\}\z}

  def render_math(latex)
    match = SIMPLE_FRACTION.match(latex)
    return %(<span class="frac"><span>#{match[1]}</span><span>#{match[2]}</span></span>) if match

    escaped = ERB::Util.html_escape(latex)
    %(<span data-controller="math" data-math-latex-value="#{escaped}">#{escaped}</span>)
  end

  def wrap_marks(html, marks)
    marks.reduce(html) do |inner, mark|
      case mark["type"]
      when "bold" then "<strong>#{inner}</strong>"
      when "italic" then "<em>#{inner}</em>"
      else inner
      end
    end
  end

  def math_text(latex)
    latex.gsub(LATEX_FRACTION, '\\1/\\2')
  end

  def node_text(node)
    case node["type"]
    when "text" then node["text"].to_s
    when "math" then math_text(node.dig("attrs", "latex").to_s)
    when "hardBreak" then " "
    else Array(node["content"]).map { |child| node_text(child) }.join
    end
  end
end
