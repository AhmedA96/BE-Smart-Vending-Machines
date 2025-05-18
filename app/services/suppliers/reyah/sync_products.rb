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
          update_or_create_variant(record)
        end
      end

      private

      def update_or_create_variant(record)
        variant = Variant.find_or_initialize_by(sku: record['id'])

        variant.update!(
          name: record['productName'],
          cost_price: record['productPrice'],
          active: true
        )
      end
    end
  end
end
