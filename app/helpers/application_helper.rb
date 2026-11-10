require "rdoc"
require "rdoc/markdown"
require "rdoc/markup/to_html"

module ApplicationHelper
  MARKDOWN_TAGS = %w[ p br h1 h2 h3 h4 h5 h6 ul ol li pre code strong em a blockquote hr ].freeze
  HEADING_ANCHOR = %r{<(h[1-6])><a href="#">(.*?)</a></\1>}m

  def nav_link_class(controller_name)
    base = "nav-link px-2"
    controller.controller_name == controller_name ? "#{base} link-secondary" : base
  end

  def render_markdown(text)
    document = RDoc::Markdown.new.parse(text.to_s)
    html = sanitize(RDoc::Markup::ToHtml.new.convert(document), tags: MARKDOWN_TAGS, attributes: %w[ href ])
    html.gsub(HEADING_ANCHOR) { "<#{Regexp.last_match(1)}>#{Regexp.last_match(2)}</#{Regexp.last_match(1)}>" }.html_safe
  end

  def week_label(course, time)
    week = course.week_of(time)
    week ? "W#{week}" : nil
  end
end
