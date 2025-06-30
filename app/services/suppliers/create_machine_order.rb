# frozen_string_literal: true

module Suppliers
  class CreateMachineOrder
    def initialize(order)
      @order = order
    end

    def call
      return unless @order&.machine&.supplier

      create_order_with_supplier
    rescue StandardError => e
      handle_error(e)
      raise e
    end

    private

    def create_order_with_supplier
      response = @order.machine.supplier.create_order(
        machine_line_product_id: @order.line_items.first.variant.sku
      )

      handle_supplier_response(response)
    end

    def handle_supplier_response(response)
      if response.success?
        parsed_response = JSON.parse(response.body)
        @order.update(machine_response: parsed_response)

        if parsed_response['success'] || parsed_response['code'] == 200
          @order.start_dispense!
        else
          @order.fail!
          Rails.logger.error("Machine order creation failed for order #{@order.id}: #{parsed_response['message']}")
        end
      else
        @order.fail!
        Rails.logger.error("Machine order creation failed for order #{@order.id}: #{response.code} - #{response.body}")
      end
    end

    def handle_error(error)
      @order.fail!
      Rails.logger.error("Error creating machine order for order #{@order.id}: #{error.message}")
    end
  end
end
