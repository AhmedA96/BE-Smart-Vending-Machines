# frozen_string_literal: true

module Suppliers
  module Reyah
    class UpdateMachineStock
      include HTTParty

      delegate :machine_no, :base_url, :auth_token, to: :@supplier

      def initialize(supplier)
        @supplier = supplier
        @machine = Machine.find_by!(machineuuid: machine_no)
      end

      def call(page: 1, per_page: 10)
        response = fetch_products(page, per_page)
        update_stocks(response['data']['records']) if response['code'].zero?
        response
      end

      private

      def fetch_products(page, per_page)
        self.class.post(
          "#{base_url}/openInterface/lineProduct/getByPage",
          headers: {
            'Authorization' => "Basic #{auth_token}",
            'Content-Type' => 'application/json'
          },
          body: {
            currentPage: page,
            pageSize: per_page,
            machineNo: machine_no
          }.to_json
        )
      end

      def update_stocks(records)
        records.each do |record|
          update_variant_stock(record)
        rescue ActiveRecord::RecordNotFound
          next
        end
      end

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
