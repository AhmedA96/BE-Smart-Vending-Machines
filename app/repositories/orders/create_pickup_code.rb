# frozen_string_literal: true

module Orders
  class CreatePickupCode
    class << self
      def call(order)
        unless order.status == 'completed'
          return error_response('Order must be paid to generate pickup code',
                                :unprocessable_content)
        end

        # Real pickup code generation in production only
        if Rails.env.production?
          machine = order.machine
          client = machine.supplier
          order_manager = client.api_service
          pickup_code = order_manager.create_pickup_order(machine, order)
          order.update!(pick_up_code: pickup_code)
          return { success: true, pickup_code: pickup_code }
        end

        # Fake pickup code generation for all other environments
        pickup_code = generate_fake_pickup_code
        order.update!(pick_up_code: pickup_code)
        { success: true, pickup_code: pickup_code }
      rescue SupplierApiError
        error_response('Failed to generate pickup code', :unprocessable_content)
      end

      private

      def generate_fake_pickup_code
        SecureRandom.random_number(100_000..999_999).to_s
      end

      def error_response(message, status)
        { success: false, error: message, status: status }
      end
    end
  end
end
