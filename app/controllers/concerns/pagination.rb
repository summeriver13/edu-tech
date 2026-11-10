module Pagination
  PER_PAGE = 50

  private

  def page_param
    [ params[:page].to_i, 1 ].max
  end

  def paginate(scope, per: PER_PAGE)
    @page = page_param
    @total = scope.count
    @total_pages = [ (@total / per.to_f).ceil, 1 ].max
    scope.offset((@page - 1) * per).limit(per)
  end
end
