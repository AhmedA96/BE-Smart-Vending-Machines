# frozen_string_literal: true

module Suppliers
  module Reyah
    class GetProducts
      include HTTParty

      delegate :machine_no, :base_url, :auth_token, to: :@supplier

      def initialize(supplier)
        @supplier = supplier
      end

      def call(page: 1, per_page: 10)
        response = make_request(page, per_page)
        SyncProducts.new(response, machine_no).call if response['code'].zero?
        response
      end

      private

      def make_request(page, per_page)
        self.class.post(
          "#{base_url}/openInterface/lineProduct/getByPage",
          headers: {
            'Authorization' => "Basic #{auth_token}",
            'Content-Type' => 'application/json'
          },
          body: {
            currentPage: page,
            pageSize: per_page,
            machineNo: machine_no
          }.to_json
        )
      end
    end
  end
end
