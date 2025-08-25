# frozen_string_literal: true

module Suppliers
  module Vendlife
    class OrderManager
      def initialize(client)
        @client = client
      end

      def get_orders(start_time:, end_time:, machineuuid: nil, page_size: 50, page_no: 1)
        params = {
          startTime: start_time.strftime('%Y-%m-%d %H:%M:%S'),
          endTime: end_time.strftime('%Y-%m-%d %H:%M:%S'),
          pageSize: page_size,
          pageNo: page_no
        }
        params[:machineUuidList] = machineuuid if machineuuid

        @client.make_request(:get, '/commorder/querycommorder', params)
      end

      def get_order_status(order_reference)
        @client.make_request(:get, '/commorder/getNeworder', { orderNo: order_reference })
      end

      def sync_orders(machine, start_time:, end_time:)
        OrderSynchronizer.new(@client, machine).sync(start_time: start_time, end_time: end_time)
      end

      def create_pickup_order(machine, order)
        PickupOrderCreator.new(@client).create(machine, order)
      end

      def cancel_pickup_order(pickup_code)
        @client.make_request(:post, '/commpick/cancalPick', { pickCode: pickup_code })
      end
    end

    # Separate class for order synchronization logic
    class OrderSynchronizer
      def initialize(client, machine)
        @client = client
        @machine = machine
        @order_manager = OrderManager.new(client)
      end

      def sync(start_time:, end_time:)
        page = 1

        loop do
          orders_data = @order_manager.get_orders(
            machineuuid: @machine.machineuuid,
            start_time: start_time,
            end_time: end_time,
            page_no: page
          )

          break if orders_data['data'].blank?

          process_orders_batch(orders_data['data'])

          break if finished_pagination?(orders_data['pageBean'], page)

          page += 1
        end
      end

      private

      def process_orders_batch(orders_data)
        orders_data.each { |order_data| sync_individual_order(order_data) }
      end

      def sync_individual_order(order_data)
        order = find_or_initialize_order(order_data)
        update_order_attributes(order, order_data)
        order.save! if order.changed?
      end

      def find_or_initialize_order(order_data)
        @machine.orders.find_or_initialize_by(number: order_data['outTradeno'])
      end

      def update_order_attributes(order, order_data)
        order.assign_attributes(
          total: order_data['totalFee'],
          status: determine_order_status(order_data['orderPayStats'], order_data['orderOutStats']),
          created_at: parse_datetime(order_data['orderTime']) || order.created_at,
          machine_response: order_data
        )
      end

      def finished_pagination?(page_bean, _current_page)
        page_bean['pageNo'] >= page_bean['pageCount']
      end

      def determine_order_status(payment_status, shipping_status)
        case [payment_status, shipping_status]
        when [1, 2] then 'completed'
        when [1, 0], [1, 1] then 'processing'
        when [1, 3], [1, 5] then 'failed'
        when [5] then 'refunded'
        else 'pending'
        end
      end

      def parse_datetime(datetime_string)
        return nil if datetime_string.blank?

        Time.zone.parse(datetime_string)
      rescue ArgumentError
        nil
      end
    end

    class PickupOrderCreator
      def initialize(client)
        @client = client
      end

      def create(machine, order)
        order_params = build_pickup_params(machine, order)

        Rails.logger.info("[PickupOrderCreator] Request params: #{order_params.to_json}")

        result = @client.make_request(:post, '/commpick/productionpick', {}, order_params)

        unless result['result'] == '200'
          raise SupplierApiError.new(result['resultDesc'],
                                     supplier_type: 'vendlife')
        end

        pickup_code = result['data']
        update_order_with_pickup_code(order, pickup_code)
        pickup_code
      end

      private

      def build_pickup_params(machine, order)
        {
          goodsList: build_goods_list(order),
          goodsNumber: order.line_items.sum(:quantity),
          machineUuid: machine.machineuuid.to_i,
          orderNo: order.number,
          orderTime: order.created_at.iso8601,
          price: order.items_total.to_f,
          lock: 1,
          timeOut: 10
        }
      end

      def build_goods_list(order)
        order.line_items.map do |line_item|
          {
            goodsNumber: line_item.quantity,
            goodsPrice: line_item.price.to_f,
            goodsUuid: line_item.variant.goods_uuid.to_i
          }
        end
      end

      def update_order_with_pickup_code(order, pickup_code)
        order.update!(
          machine_response: (order.machine_response || {}).merge(pickup_code: pickup_code)
        )
      end
    end
  end
end
