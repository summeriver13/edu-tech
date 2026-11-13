module PublicCache
  # Without a CDN, browser caching would serve anonymous HTML to a user who
  # has just logged in. Keep browser revalidation on every request.
  BROWSER_MAX_AGE = 0
  EDGE_MAX_AGE = 300
  STALE_WHILE_REVALIDATE = 60
  STALE_IF_ERROR = 600

  private

  def cache_public_page(last_modified:, etag:)
    return if logged_in?

    @public_cache_page = true
    fresh_when(etag: etag, last_modified: last_modified, public: true)
    response.cache_control[:max_age] = BROWSER_MAX_AGE
    response.cache_control[:extras] = [ "s-maxage=#{EDGE_MAX_AGE}" ]
    response.headers["CDN-Cache-Control"] = cdn_cache_control
  end

  def cdn_cache_control
    [
      "public",
      "max-age=#{EDGE_MAX_AGE}",
      "stale-while-revalidate=#{STALE_WHILE_REVALIDATE}",
      "stale-if-error=#{STALE_IF_ERROR}"
    ].join(", ")
  end
end
