module ExplainersHelper
  # A paragraph of an article: plain text with **bold** for the one phrase a
  # reader should not miss. Escaped first, so the YAML can carry no markup of
  # its own — only the emphasis this helper puts back.
  def explainer_text(text)
    escaped = ERB::Util.html_escape(text.to_s)
    escaped.gsub(/\*\*(.+?)\*\*/) { "<strong>#{Regexp.last_match(1)}</strong>" }.html_safe # rubocop:disable Rails/OutputSafety -- escaped above
  end
end
