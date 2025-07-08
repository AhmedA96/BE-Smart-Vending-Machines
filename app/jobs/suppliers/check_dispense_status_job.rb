# frozen_string_literal: true

module Suppliers
  class CheckDispenseStatusJob < ApplicationJob
    queue_as :suppliers
    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    def perform(order_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      order = Order.find_by(id: order_id)
      return unless order&.pending_dispense? && order.machine&.supplier

      supplier_service = create_supplier_service(order.machine)
      return unless supplier_service

      begin
        response = supplier_service.get_order_details(
          order_no: order.machine_response['order_no']
        )

        if response.success?
          parsed_response = JSON.parse(response.body)

          if parsed_response['status'] == 'completed' || parsed_response['code'] == 200
            order.complete_dispense!
          elsif parsed_response['status'] == 'failed' || parsed_response['error']
            order.fail!
            Rails.logger.error("Dispense failed for order #{order_id}: #{parsed_response['message']}")
          elsif order.pending_dispense?
            # Still pending, schedule another check
            self.class.set(wait: 30.seconds).perform_later(order_id)
          end
        else
          Rails.logger.error("Failed to check dispense status for order #{order_id}: #{response.code} - #{response.body}") # rubocop:disable Layout/LineLength
          # Retry through job retry mechanism
          raise StandardError, "Failed to check dispense status: #{response.code}"
        end
      rescue StandardError => e
        Rails.logger.error("Error checking dispense status for order #{order_id}: #{e.message}")
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
