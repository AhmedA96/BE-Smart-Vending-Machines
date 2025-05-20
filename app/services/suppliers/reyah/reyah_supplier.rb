# frozen_string_literal: true

module Suppliers
  module Reyah
    class ReyahSupplier < BaseSupplier
      def get_products(page: 1, per_page: 10)
        Reyah::GetProducts.new(self).call(page: page, per_page: per_page)
      end

      def create_order(machine_line_product_id:)
        Reyah::CreateOrder.new(self).call(machine_line_product_id: machine_line_product_id)
      end

      def get_order_details(order_no:)
        Reyah::GetOrder.new(self).call(order_no: order_no)
      end
    end
  end
end
