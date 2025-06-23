# frozen_string_literal: true

module Suppliers
  class SyncProductsJob
    include Sidekiq::Job

    sidekiq_options queue: :suppliers, retry: 3

    def perform
      Machine.includes(:supplier).find_each do |machine|
        next unless machine.supplier && machine.active?

        begin
          supplier_service = case machine.supplier.name.downcase
                             when 'reyah'
                               Suppliers::ReyahSupplier.new(machine.supplier, machine.external_machine_id)
                             when 'vendlife'
                               Suppliers::VendlifeSupplier.new(machine.supplier, machine.external_machine_id)
                             else
                               Rails.logger.error("Unsupported supplier: #{machine.supplier.name}")
                               next
                             end

          supplier_service.get_products
        rescue StandardError => e
          Rails.logger.error("Failed to sync products for machine #{machine.id}: #{e.message}")
          # Optionally notify your error tracking service here
          next
        end
      end
    end
  end
end
