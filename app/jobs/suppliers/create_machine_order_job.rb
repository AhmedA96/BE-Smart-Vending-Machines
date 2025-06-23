# frozen_string_literal: true

module Suppliers
  class CreateMachineOrderJob < ApplicationJob
    queue_as :suppliers
    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    def perform(order_id) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      order = Order.find_by(id: order_id)
      return unless order&.machine&.supplier

      supplier_service = create_supplier_service(order.machine)
      return unless supplier_service

      begin
        response = supplier_service.create_order(
          machine_line_product_id: order.line_items.first.variant.sku
        )

        if response.success?
          parsed_response = JSON.parse(response.body)
          order.update(machine_response: parsed_response)

          if parsed_response['success'] || parsed_response['code'] == 200
            order.start_dispense!
          else
            order.fail!
            Rails.logger.error("Machine order creation failed for order #{order_id}: #{parsed_response['message']}")
          end
        else
          order.fail!
          Rails.logger.error("Machine order creation failed for order #{order_id}: #{response.code} - #{response.body}")
        end
      rescue StandardError => e
        order.fail!
        Rails.logger.error("Error creating machine order for order #{order_id}: #{e.message}")
        raise e
      end
    end

    private

    def create_supplier_service(machine)
      case machine.supplier.name.downcase
      when 'reyah'
        Suppliers::ReyahSupplier.new(machine.supplier, machine.external_machine_id)
      when 'vendlife'
        Suppliers::VendlifeSupplier.new(machine.supplier, machine.external_machine_id)
      else
        Rails.logger.error("Unsupported supplier: #{machine.supplier.name}")
        nil
      end
    end
  end
end
