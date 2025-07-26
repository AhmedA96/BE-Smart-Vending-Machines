# frozen_string_literal: true

module Suppliers
  module Vendlife
    class StatisticsManager
      def initialize(client)
        @client = client
      end

      def get_sales_statistics(start_time:, end_time:, machine_id: nil, goods_id: -1)
        params = {
          startTime: start_time.strftime('%Y-%m-%d'),
          endTime: end_time.strftime('%Y-%m-%d'),
          mid: machine_id || -1,
          goodsId: goods_id
        }

        @client.make_request(:get, '/commorder/queryOrderSaleStatistics', params)
      end
    end
  end
end
