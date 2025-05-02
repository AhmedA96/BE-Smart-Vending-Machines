# frozen_string_literal: true

module Products
  class FilterService
    attr_reader :params

    def initialize(params = {})
      @params = params
    end

    def call
      products = Product.active

      return products if params.blank?

      apply_filters(products)
    end

    private

    def apply_filters(products)
      products
        .then { |p| filter_by_machine(p) }
        .then { |p| filter_by_category(p) }
        .then { |p| filter_by_price_list(p) }
        .then { |p| filter_by_price_range(p) }
        .then { |p| sort_by_price_if_needed(p) }
        .then { |p| filter_by_stock(p) }
        .then { |p| filter_by_search(p) }
    end

    def filter_by_machine(products)
      return products if params[:machine_id].blank?

      products.filtered_by_machine(params[:machine_id])
    end

    def filter_by_category(products)
      return products if params[:category_id].blank?

      products.by_category(params[:category_id])
    end

    def filter_by_price_list(products)
      return products if params[:price_list_id].blank?

      products.with_price_list(params[:price_list_id])
    end

    def filter_by_price_range(products)
      return products unless params[:min_price].present? && params[:max_price].present?

      products.by_price_range_for_price_list(
        params[:price_list_id],
        params[:min_price],
        params[:max_price]
      )
    end

    def sort_by_price_if_needed(products)
      return products if params[:sort_direction].blank?

      products.sort_by_price(
        params[:price_list_id],
        params[:sort_direction]
      )
    end

    def filter_by_stock(products)
      return products if params[:min_quantity].blank?

      products.with_stock_availability(
        params[:machine_id],
        params[:min_quantity] || 1
      )
    end

    def filter_by_search(products)
      return products if params[:search].blank?

      products.search(params[:search])
    end
  end
end
