# frozen_string_literal: true

module Paginable
  extend ActiveSupport::Concern

  private

  def paginate(collection)
    collection.page(page).per(per_page)
  end

  def page
    params[:page] || 1
  end

  def per_page
    params[:per_page] || 10
  end

  def pagination_meta(paginated_collection)
    {
      current_page: paginated_collection.current_page,
      total_pages: paginated_collection.total_pages,
      total_count: paginated_collection.total_count,
      next_page: paginated_collection.next_page,
      prev_page: paginated_collection.prev_page
    }
  end
end
