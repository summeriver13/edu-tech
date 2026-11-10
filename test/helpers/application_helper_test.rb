require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "renders markdown as html" do
    html = render_markdown("# 标题\n\n段落 **粗体**")

    assert_includes html, "<h1>标题</h1>"
    assert_includes html, "<strong>粗体</strong>"
  end

  test "drops scripts and event handlers" do
    html = render_markdown("<script>alert(1)</script>\n\n[链接](https://example.com)")

    assert_not_includes html, "<script>"
    assert_includes html, "https://example.com"
  end
end
