# frozen_string_literal: true

module Suppliers
  module Vendlife
    class InventoryManager
      def initialize(client)
        @client = client
      end

      def get_inventory(machineuuid = nil)
        params = {}
        params[:machineUuid] = machineuuid if machineuuid

        @client.make_request(:get, '/commodityinfo/queryGoodsStock', params)
      end

      def get_machine_aisles(machineuuid)
        @client.make_request(:get, '/commodityinfo/querycommodityinfo',
                             { machineUuid: machineuuid })
      end

      def update_machine_aisles(machineuuid, aisle_data)
        payload = {
          machineUuid: machineuuid,
          list: aisle_data
        }

        @client.make_request(:put, '/commodityinfo/updatecommodityinfolist', {}, payload)
      end

      def sync_inventory(machine)
        aisles_data = get_machine_aisles(machine.machineuuid)
        return if aisles_data['data'].blank?

        aisles_data['data'].each do |aisle_data|
          sync_aisle_inventory(machine, aisle_data)
        end
      end

      private

      def sync_aisle_inventory(machine, aisle_data)
        return unless aisle_data['goodsUuid']&.positive?

        machine_item = find_machine_item_by_goods_uuid(machine, aisle_data['goodsUuid'])
        return unless machine_item

        machine_item.update!(
          stock: aisle_data['presentNumber'] || 0,
          line_number: aisle_data['arrivalName']
        )
      end

      def find_machine_item_by_goods_uuid(machine, goods_uuid)
        machine.machine_items.joins(:variant)
               .find_by(variants: { external_product_id: goods_uuid.to_s })
      end
    end
  end
end
