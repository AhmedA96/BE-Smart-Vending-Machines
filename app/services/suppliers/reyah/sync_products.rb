# frozen_string_literal: true

module Suppliers
  module Reyah
    class SyncProducts
      def initialize(response_data, machine_no)
        @records = response_data.dig('data', 'records') || []
        @machine = Machine.find_by!(external_machine_id: machine_no)
      end

      def call
        @records.each do |record|
          update_variant_stock(record)
        rescue ActiveRecord::RecordNotFound
          next
        end
      end

      private

      def update_variant_stock(record)
        variant = Variant.find_by!(sku: record['id'])
        machine_item = MachineItem.find_or_initialize_by(machine: @machine, variant: variant)

        machine_item.update!(
          stock: record['nowStock'].to_i,
          line_number: record['lineNum'],
          updated_at: Time.current
        )
      end
    end
  end
end
