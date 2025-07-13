# frozen_string_literal: true

module Suppliers
  class VendlifeService < BaseService
    attr_reader :client, :machine_manager, :inventory_manager, :product_manager,
                :order_manager, :dispensing_manager, :statistics_manager

    def initialize(supplier)
      super

      @client = Vendlife::BaseClient.new(supplier)
      @machine_manager = Vendlife::MachineManager.new(@client)
      @inventory_manager = Vendlife::InventoryManager.new(@client)
      @product_manager = Vendlife::ProductManager.new(@client)
      @order_manager = Vendlife::OrderManager.new(@client)
      @statistics_manager = Vendlife::StatisticsManager.new(@client)
    end

    # ==================== AUTHENTICATION DELEGATION ====================

    def authenticate
      @client.token_valid? ? @client.headers['Authorization'] : @client.refresh_token!
    end

    delegate :refresh_token!, to: :@client

    delegate :token_valid?, to: :@client

    # ==================== MACHINE DELEGATION ====================

    def get_machines(machineuuid = nil)
      @machine_manager.get_machines(machineuuid)
    end

    delegate :get_machine_status, to: :@machine_manager

    delegate :sync_machine_data, to: :@machine_manager

    # ==================== INVENTORY DELEGATION ====================

    def get_inventory(machineuuid = nil)
      @inventory_manager.get_inventory(machineuuid)
    end

    delegate :sync_inventory, to: :@inventory_manager

    def update_inventory(machine, inventory_data)
      @inventory_manager.update_machine_aisles(machine.machineuuid, inventory_data)
    end

    # ==================== PRODUCT DELEGATION ====================

    def get_products(machineuuid = nil)
      if machineuuid
        @product_manager.get_machine_products(machineuuid)
      else
        @product_manager.get_all_products
      end
    end

    delegate :sync_products, to: :@product_manager

    # ==================== ORDER DELEGATION ====================

    def get_orders(start_time:, end_time:, machineuuid: nil, **)
      @order_manager.get_orders(
        machineuuid: machineuuid,
        start_time: start_time,
        end_time: end_time,
        **
      )
    end

    delegate :get_order_status, to: :@order_manager

    def sync_orders(machine, start_time:, end_time:)
      @order_manager.sync_orders(machine, start_time: start_time, end_time: end_time)
    end

    # ==================== DISPENSING DELEGATION ====================

    delegate :dispense_product, to: :@dispensing_manager

    delegate :create_pickup_order, to: :@order_manager

    delegate :cancel_pickup_order, to: :@order_manager

    # ==================== STATISTICS DELEGATION ====================

    def get_sales_statistics(start_time:, end_time:, machine_id: nil, **)
      @statistics_manager.get_sales_statistics(
        start_time: start_time,
        end_time: end_time,
        machine_id: machine_id,
        **
      )
    end

    # ==================== CONFIGURATION IMPLEMENTATION ====================

    def get_machine_configuration(machineuuid)
      {
        machine_info: @machine_manager.get_machines(machineuuid),
        aisles: @inventory_manager.get_machine_aisles(machineuuid),
        inventory: @inventory_manager.get_inventory(machineuuid)
      }
    end

    def update_machine_configuration(machineuuid, config)
      results = {}

      results[:aisles] = @inventory_manager.update_machine_aisles(machineuuid, config[:aisles]) if config[:aisles]

      results[:price_tags] = @machine_manager.update_price_tags(machineuuid, config[:price_tags]) if config[:price_tags]

      results
    end

    # ==================== VENDLIFE-SPECIFIC FEATURES ====================

    def supported_features
      super.merge(
        temperature_monitoring: true,
        energy_management: true,
        price_tag_updates: true,
        cabinet_control: true
      )
    end

    delegate :get_cabinet_temperature_humidity, to: :@machine_manager

    delegate :update_price_tags, to: :@machine_manager

    delegate :sync_cabinet_mappings, to: :@inventory_manager
  end
end
