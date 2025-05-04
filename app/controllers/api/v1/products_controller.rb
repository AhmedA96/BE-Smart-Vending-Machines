# frozen_string_literal: true

module Api
  module V1
    class ProductsController < ApplicationController
      include Products::Filterable
      include Products::Sortable

      before_action :set_product, only: %i[show]

      def index
        products = main_products.includes(:variants).includes(:translations)
        products = apply_filters(products)
        @products = paginate(products)
      end

      def machine_products
        machine_id = params[:machine_id]
        @products = paginate(Product.filtered_by_machine(machine_id))
      end

      def show; end

      private

      def apply_filters(products)
        products = apply_price_range_filter(products) if price_range_params_present?
        products = apply_stock_availability_filter(products) if stock_availability_param_present?
        if sort_params_present?
          apply_sort_filter(products)
        else
          products.order_by_position
        end
      end

      def main_products
        Product.active
      end

      def set_product
        @product = Product.find(params[:id])
      end
    end
  end
end
