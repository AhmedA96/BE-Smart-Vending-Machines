# frozen_string_literal: true

class InventorySyncJob < ApplicationJob
  queue_as :default

  def perform
    Machine.joins(:supplier)
           .where(suppliers: { name: 'vendlife' })
           .includes(:supplier, machine_items: :variant)
           .find_each do |machine|
      sync_machine_inventory(machine)
    end
  end

  private

  def sync_machine_inventory(machine)
    service = build_vendlife_service(machine)
    inventory_data = fetch_inventory_data(service, machine.machineuuid)
    return unless inventory_data

    inventory_data.each { |item| update_machine_item_stock(machine, item) }
  end

  def build_vendlife_service(machine)
    service = Suppliers::VendlifeService.new(machine.supplier)
    service.authenticate
    service
  end

  def fetch_inventory_data(service, machine_uuid)
    response = service.get_inventory(machine_uuid)
    response&.dig('data').presence
  end

  def update_machine_item_stock(machine, inventory_item)
    goods_uuid = extract_goods_uuid(inventory_item)
    return unless goods_uuid

    machine_item = find_machine_item(machine, goods_uuid)
    return unless machine_item

    update_stock_if_changed(machine_item, inventory_item)
  end

  def extract_goods_uuid(inventory_item)
    inventory_item['goodsUuid']&.to_s&.presence
  end

  def find_machine_item(machine, goods_uuid)
    machine.machine_items
           .joins(:variant)
           .find_by(variants: { goods_uuid: goods_uuid })
  end

  def update_stock_if_changed(machine_item, inventory_item)
    new_stock = inventory_item['availableInventory'] || inventory_item['inventory'] || 0
    machine_item.update!(stock: new_stock) if machine_item.stock != new_stock
  end
end
