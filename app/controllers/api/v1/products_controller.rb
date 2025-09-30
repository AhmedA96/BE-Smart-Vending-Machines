# frozen_string_literal: true

module Api
  module V1
    class ProductsController < ApplicationController
      include Products::Filterable
      include Products::PriceListFindable
      include Products::Sortable

      before_action :set_product, only: %i[show]

      def index
        products = main_products.includes(:variants).includes(:translations)
        products = apply_filters(products)
        products.ransack_filter(filtered_params)
        @products = paginate(products)
      end

      def machine_products
        machine_id = params[:machine_id]
        @machine = Machine.includes(location: { price_list: :price_list_items }).find(machine_id)
        products = Product.with_priced_variants_for_machine(@machine)
        products = apply_filters(products)
        @products = paginate(products)
      end

      def show; end

      private

      def apply_filters(products)
        products = apply_machine_filter(products) if machine_id_param_present?
        products = apply_price_range_filter(products) if price_range_params_present?
        products = apply_stock_availability_filter(products) if stock_availability_param_present?
        products = apply_category_filter(products) if category_id_param_present?
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

      def find_machine
        @machine = Machine.find_by(id: params.dig(:q, :machine_id))
      end
    end
  end
end
