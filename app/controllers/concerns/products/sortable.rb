# frozen_string_literal: true

module Products
  module Sortable
    extend ActiveSupport::Concern

    included do
      private_methods

      def sort_params_present?
        params[:sort_price].present?
      end

      def apply_sort_filter(products)
        sort_direction = %w[asc desc].include?(params[:sort_price]) ? params[:sort_price] : 'asc'
        products.sort_by_price(sort_direction)
      end
    end
  end
end
