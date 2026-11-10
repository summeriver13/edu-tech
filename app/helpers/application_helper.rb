module ApplicationHelper
  def nav_link_class(controller_name)
    base = "nav-link px-2"
    controller.controller_name == controller_name ? "#{base} link-secondary" : base
  end

  def render_markdown(text)
    MarkdownRenderer.render(text)
  end

  def lesson_html(lesson)
    lesson.body_html.presence&.html_safe || render_markdown(lesson.body)
  end

  def week_label(course, time)
    week = course.week_of(time)
    week ? "W#{week}" : nil
  end
end
