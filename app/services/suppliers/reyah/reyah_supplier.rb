# frozen_string_literal: true

module Suppliers
  module Reyah
    class ReyahSupplier < BaseSupplier
      def get_products(page: 1, per_page: 10)
        Reyah::GetProducts.new(self).call(page: page, per_page: per_page)
      end
    end
  end
end
