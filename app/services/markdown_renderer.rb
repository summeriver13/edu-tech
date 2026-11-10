require "rdoc"
require "rdoc/markdown"
require "rdoc/markup/to_html"

class MarkdownRenderer
  TAGS = %w[ p br h1 h2 h3 h4 h5 h6 ul ol li pre code strong em a blockquote hr ].freeze
  ATTRIBUTES = %w[ href ].freeze
  HEADING_ANCHOR = %r{<(h[1-6])><a href="#">(.*?)</a></\1>}m

  def self.render(text)
    document = RDoc::Markdown.new.parse(text.to_s)
    html = ActionController::Base.helpers.sanitize(RDoc::Markup::ToHtml.new.convert(document), tags: TAGS, attributes: ATTRIBUTES)
    html.gsub(HEADING_ANCHOR) { "<#{Regexp.last_match(1)}>#{Regexp.last_match(2)}</#{Regexp.last_match(1)}>" }.html_safe
  end
end
