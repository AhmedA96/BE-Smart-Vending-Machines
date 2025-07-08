# frozen_string_literal: true

module Api
  module V1
    class ProductsController < ApplicationController
      include Products::Filterable
      include Products::PriceListFindable
      include Products::Sortable

      before_action :set_product, only: %i[show]
      before_action :set_location, only: %i[by_brand_and_location by_category_and_location]
      before_action :set_category, only: %i[by_category_and_location]
      before_action :set_brand, only: %i[by_brand_and_location]

      def index
        products = main_products.includes(:variants).includes(:translations)
        products = apply_filters(products)
        products.ransack_filter(filtered_params)
        @products = paginate(products)
      end

      def machine_products
        machine_id = params[:machine_id]
        @machine = Machine.includes(location: { price_list: :price_list_items }).find(machine_id)
        @products = paginate(Product.includes(:variants)
                           .filtered_by_machine(machine_id))
      end

      def by_category_and_location
        location_id = params[:location_id]
        category_id = params[:category_id]

        @products = paginate(Product.by_location_and_category(location_id, category_id)
                           .includes(:variants, :categories))

        render :index
      end

      def by_brand_and_location
        location_id = params[:location_id]
        brand_id = params[:brand_id]

        @products = paginate(Product.by_location_and_brand(location_id, brand_id)
                    .includes(:brand, :variants, :translations))

        render :index
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

      def set_location
        @location = Location.find(params[:location_id])
      end

      def set_category
        @category = Category.find(params[:category_id])
      end

      def set_brand
        @brand = Brand.find(params[:brand_id])
      end
    end
  end
end
