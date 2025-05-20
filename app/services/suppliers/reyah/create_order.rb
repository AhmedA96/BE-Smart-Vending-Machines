# frozen_string_literal: true

module Suppliers
  module Reyah
    class CreateOrder
      include HTTParty

      delegate :machine_no, :base_url, :auth_token, to: :@supplier

      def initialize(supplier)
        @supplier = supplier
      end

      def call(machine_line_product_id:)
        make_request(machine_line_product_id)
      end

      private

      def make_request(machine_line_product_id)
        self.class.post(
          "#{base_url}/openInterface/order/createOrder",
          headers: {
            'Authorization' => "Basic #{auth_token}",
            'Content-Type' => 'application/json'
          },
          body: {
            machineNo: @supplier.machine_no,
            shopType: 1,
            machineLineProductId: machine_line_product_id,
            buyNum: 1
          }.to_json
        )
      end
    end
  end
end
