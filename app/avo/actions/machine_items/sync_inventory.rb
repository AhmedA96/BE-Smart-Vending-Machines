# frozen_string_literal: true

# app/avo/actions/machine_items/sync_inventory.rb
module Avo
  module Actions
    module MachineItems
      class SyncInventory < Avo::BaseAction
        self.name = 'Select machine(s) to update Inventory'
        self.message = 'This will fetch the latest inventory data from Supplier and update stock levels.'
        self.confirm_button_label = 'Update Inventory'
        self.cancel_button_label = 'Cancel'
        self.no_confirmation = false

        # Available on both index and show pages
        self.visible = -> { true }

        def handle(query:, fields:, resource:, **_args) # rubocop:disable Lint/UnusedMethodArgument
          machines = query.map(&:machine).uniq
          synced_count = 0
          failed_machines = []

          machines.each do |machine|
            result = sync_machine_inventory(machine)
            synced_count += result[:count]
            failed_machines << result[:error] if result[:error]
          end

          build_result_message(synced_count, machines.count, failed_machines)
        end

        private

        def sync_machine_inventory(machine)
          service = initialize_service(machine)
          return error_result(machine, 'no supplier configured') unless service

          inventory_data = fetch_inventory(service, machine)
          return error_result(machine, 'no inventory data returned') unless inventory_data

          update_machine_items(machine, inventory_data)
        rescue StandardError => e
          log_error(machine, e)
          error_result(machine, e.message)
        end

        def initialize_service(machine)
          return nil unless machine.supplier

          service = Suppliers::VendlifeService.new(machine.supplier)
          service.refresh_token! unless service.token_valid?
          service
        end

        def fetch_inventory(service, machine)
          inventory_data = service.get_inventory(machine.machineuuid)
          inventory_data if inventory_data && inventory_data['data']
        end

        def update_machine_items(machine, inventory_data)
          count = 0

          inventory_data['data'].each do |item|
            count += 1 if sync_inventory_item(machine, item)
          end

          { count: count }
        end

        def sync_inventory_item(machine, item)
          variant = Variant.find_by(goods_uuid: item['goodsUuid'])
          return false unless variant

          machine_item = find_or_build_machine_item(machine, variant)
          stock_level = item['inventory'] || item['availableInventory'] || 0

          machine_item.update(stock: stock_level)
        end

        def find_or_build_machine_item(machine, variant)
          machine_item = machine.machine_items.find_or_initialize_by(variant: variant)

          unless machine_item.persisted?
            max_line = machine.machine_items.maximum(:line_number) || 0
            machine_item.line_number = max_line + 1
          end

          machine_item
        end

        def error_result(machine, message)
          { count: 0, error: "#{machine.name} (#{message})" }
        end

        def log_error(machine, exception)
          Rails.logger.error "Failed to sync inventory for machine #{machine.id}: #{exception.message}"
        end

        def build_result_message(synced_count, machine_count, failed_machines)
          if failed_machines.empty?
            succeed "Successfully synced #{synced_count} items from #{machine_count} machine(s)"
          else
            error "Synced #{synced_count} items, but failed for: #{failed_machines.join(', ')}"
          end
        end
      end
    end
  end
end
