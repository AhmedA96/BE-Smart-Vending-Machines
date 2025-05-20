# frozen_string_literal: true

module Suppliers
  module Reyah
    class GetOrderDetails
      include HTTParty

      delegate :machine_no, :base_url, :auth_token, to: :@supplier

      def initialize(supplier)
        @supplier = supplier
      end

      def call(order_no:)
        make_request(order_no)
      end

      private

      def make_request(order_no)
        self.class.post(
          "#{base_url}/openInterface/order/orderDetail",
          headers: {
            'Authorization' => "Basic #{auth_token}",
            'Content-Type' => 'application/json'
          },
          body: {
            orderNo: order_no,
            machineNo: machine_no
          }.to_json
        )
      end
    end
  end
end
