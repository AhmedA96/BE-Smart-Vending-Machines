# frozen_string_literal: true

module Suppliers
  module Reyah
    class GetProducts
      include HTTParty

      def initialize(supplier)
        @supplier = supplier
      end

      def call(page: 1, per_page: 10)
        response = make_request(page, per_page)
        SyncProducts.new(response, @machine_no).call if response['code'].zero?
        response
      end

      private

      def make_request(page, per_page)
        self.class.post(
          "#{@supplier.base_url}/openInterface/lineProduct/getByPage",
          headers: {
            'Authorization' => "Basic #{@supplier.auth_token}",
            'Content-Type' => 'application/json'
          },
          body: {
            currentPage: page,
            pageSize: per_page,
            machineNo: @supplier.machine_no
          }.to_json
        )
      end
    end
  end
end
