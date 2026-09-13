module StaticPagesHelper
  # A link to one of the landing page's sections, from anywhere in the public
  # shell.
  #
  # The header and footer are shared with the curriculum pages, where a bare
  # "#how" points at a section that is not on the document — so the link did
  # nothing at all, silently, which is the worst way for navigation to fail. Off
  # the landing page it becomes "/#how", which loads the page and scrolls; on it
  # the anchor stays bare so the browser scrolls in place instead of navigating.
  def landing_section_path(anchor)
    current_page?(root_path) ? "##{anchor}" : "#{root_path}##{anchor}"
  end
end
