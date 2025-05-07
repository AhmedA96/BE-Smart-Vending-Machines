# frozen_string_literal: true

module Products
  module Cacheable
    extend ActiveSupport::Concern

    included do
      before_action :set_cache_key, only: %i[index show]
    end

    private

    def set_cache_key
      action = action_name.to_sym
      @cache_key = send(:"cache_key_for_#{action}")
    end

    def cache_key_for_index
      "products_index_price_list_#{@price_list&.id}_#{filtered_params.to_query}"
    end

    def cache_key_for_show
      "product_show_#{params[:id]}_price_list_#{@price_list&.id}"
    end

    def cache_key_for_default
      nil
    end
  end
end
