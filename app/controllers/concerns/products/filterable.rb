# frozen_string_literal: true

module Products
  module Filterable
    extend ActiveSupport::Concern

    def filtered_params
      params.permit(
        :order_id, :page, :per_page, :sorts, :sort_price, :format,
        q: %i[
          machine_id
          product_translations_presentation_cont
          product_translations_description_cont
          brand_id_eq
          product_translations_presentation_start
          product_translations_description_start
          price_for_price_list_gteq
          price_for_price_list_lteq
          stock_availability
          category_id
        ]
      )
    end

    def price_range_params_present?
      params[:q] &&
        params[:q][:price_for_price_list_gteq].present? &&
        params[:q][:price_for_price_list_lteq].present?
    end

    def apply_price_range_filter(products)
      products.by_price_range_for_price_list(
        @price_list&.id,
        params[:q][:price_for_price_list_gteq],
        params[:q][:price_for_price_list_lteq]
      )
    end

    def stock_availability_param_present?
      params[:q] && stock_availability_param.present?
    end

    def apply_stock_availability_filter(products)
      products.with_stock_availability(@machine, stock_availability_param.to_i)
    end

    def category_id_param_present?
      params[:q] && category_id_param.present?
    end

    def apply_category_filter(products)
      products.by_category(category_id_param)
    end

    def machine_id_param_present?
      params[:q] && machine_id_param.present?
    end

    def apply_machine_filter(products)
      products.filtered_by_machine(machine_id_param)
    end

    def machine_id_param
      params[:q][:machine_id]
    end

    def stock_availability_param
      params[:q][:stock_availability]
    end

    def category_id_param
      params[:q][:category_id]
    end
  end
end
