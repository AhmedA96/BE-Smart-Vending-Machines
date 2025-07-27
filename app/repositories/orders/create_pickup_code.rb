# frozen_string_literal: true

module Orders
  class CreatePickupCode
    class << self
      def call(order)
        unless order.status == 'paid'
          return error_response('Order must be paid to generate pickup code',
                                :unprocessable_content)
        end

        machine = order.machine
        client = machine.supplier
        order_manager = Suppliers::VendlifeService.new(client)
        pickup_code = order_manager.create_pickup_order(machine, order)

        order.update!(pick_up_code: pickup_code)

        { success: true, pickup_code: pickup_code }
      rescue SupplierApiError
        error_response('Failed to generate pickup code', :unprocessable_entity)
      end

      private

      def error_response(message, status)
        { success: false, error: message, status: status }
      end
    end
  end
end
