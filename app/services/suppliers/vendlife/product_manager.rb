# frozen_string_literal: true

module Suppliers
  module Vendlife
    class ProductManager
      def initialize(client)
        @client = client
      end

      def fetch_all_products
        @client.make_request(:get, '/commgoods/queryAllGoods')
      end

      def get_machine_products(machineuuid)
        @client.make_request(:get, '/customgoods/querymachinegoods',
                             { machineUuid: machineuuid })
      end

      def sync_products(machine)
        products_data = get_machine_products(machine.machineuuid)
        return if products_data['data'].blank?

        # Sync categories first if they exist
        sync_categories(products_data['data']['commGoodsModel']) if products_data['data']['commGoodsModel']

        # Then sync products
        sync_product_list(machine, products_data['data']['goodsList']) if products_data['data']['goodsList']
      end

      def update_product_service(goods_id, is_open, service_params)
        payload = {
          goodsId: goods_id,
          isOpen: is_open,
          serviceParams: service_params
        }

        @client.make_request(:post, '/commgoods/updateGoodsService', {}, payload)
      end

      def delete_custom_products(product_ids)
        payload = { idList: product_ids }
        @client.make_request(:post, '/commgoods/delGoods', {}, payload)
      end

      private

      def sync_categories(categories_data)
        categories_data.each do |category_data|
          sync_category(category_data)
        end
      end

      def sync_category(category_data)
        return unless defined?(MachineCategory)

        category = MachineCategory.find_or_initialize_by(
          # You might need a field to store external category ID
          name: category_data['typeName']
        )

        category.assign_attributes(
          description: category_data['typeRemark']
        )

        category.save! if category.changed?
        category
      end

      def sync_product_list(machine, products_data)
        products_data.each do |product_data|
          sync_machine_product(machine, product_data)
        end
      end

      def sync_machine_product(machine, product_data)
        variant = machine.variants.find_by(external_product_id: product_data['uuid'].to_s)
        return unless variant

        machine_item = machine.machine_items.find_or_initialize_by(variant: variant)

        # Update any additional product-specific data here
        machine_item.save! if machine_item.new_record?
      end
    end
  end
end
