module ApplicationHelper
  def nav_link_class(controller_name)
    base = "nav-link px-2"
    controller.controller_name == controller_name ? "#{base} link-secondary" : base
  end
end
