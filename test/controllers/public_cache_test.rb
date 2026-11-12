require "test_helper"

class PublicCacheTest < ActionDispatch::IntegrationTest
  CDN_CACHE_CONTROL = "public, max-age=300, stale-while-revalidate=60, stale-if-error=600"

  setup do
    @course = courses(:one)
    @lesson = lessons(:one)
  end

  test "login page is not publicly cacheable" do
    get new_session_url

    assert_response :success
    assert_equal "private, no-store", response.headers["CDN-Cache-Control"]
  end

  test "anonymous course list is publicly cacheable" do
    get courses_url

    assert_response :success
    assert_public_cache
    assert_nil response.headers["Set-Cookie"]
    assert_no_csrf_tags
  end

  test "anonymous course page is publicly cacheable and revalidates" do
    get course_url(@course)

    assert_response :success
    assert_public_cache
    assert_nil response.headers["Set-Cookie"]
    assert_no_csrf_tags
    etag = response.headers["ETag"]
    assert etag.present?

    get course_url(@course), headers: { "If-None-Match" => etag }

    assert_response :not_modified
    assert_equal CDN_CACHE_CONTROL, response.headers["CDN-Cache-Control"]
  end

  test "anonymous lesson page is publicly cacheable" do
    get course_lesson_url(@course, @lesson)

    assert_response :success
    assert_public_cache
    assert_nil response.headers["Set-Cookie"]
    assert_no_csrf_tags
  end

  test "logged in pages are not publicly cacheable" do
    log_in_as users(:two)

    [ courses_url, course_url(@course), course_lesson_url(@course, @lesson) ].each do |url|
      get url

      assert_response :success
      assert_equal "private, no-store", response.headers["CDN-Cache-Control"]
      assert_not_includes response.headers["Cache-Control"], "public"
    end
  end

  test "public pages skip csrf tags under forgery protection" do
    with_forgery_protection do
      [ courses_url, course_url(@course), course_lesson_url(@course, @lesson) ].each do |url|
        get url

        assert_response :success
        assert_nil response.headers["Set-Cookie"]
        assert_select "meta[name=csrf-token]", count: 0
        assert_select "input[name=authenticity_token]", count: 0
      end
    end
  end

  test "logged in pages keep the csrf meta tag" do
    log_in_as users(:two)

    with_forgery_protection do
      get course_url(@course)

      assert_select "meta[name=csrf-token]"
    end
  end

  private

  def assert_public_cache
    cache_control = response.headers["Cache-Control"]
    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=120"
    assert_includes cache_control, "s-maxage=300"
    assert_equal CDN_CACHE_CONTROL, response.headers["CDN-Cache-Control"]
  end

  def assert_no_csrf_tags
    assert_select "meta[name=csrf-token]", count: 0
    assert_select "input[name=authenticity_token]", count: 0
  end

  def with_forgery_protection
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end
end
