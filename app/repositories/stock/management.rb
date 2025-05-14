# frozen_string_literal: true

module Stock
  class Management
    def self.call(variant_id, quantity, machine_id)
      variant = Variant.find(variant_id)
      machine = Machine.find(machine_id)

      validate_stock!(variant, machine, quantity)
      update_variant_stock(variant, machine, quantity) if variant.present?
    end

    def self.validate_stock!(variant, machine, quantity)
      stock_quantity = variant.machine_stock(machine)
      return if stock_quantity.to_i >= quantity.to_i

      raise StockError, 'Insufficient stock for one or more items'
    end

    def self.update_variant_stock(variant, machine, quantity)
      current_stock = variant.machine_stock(machine)
      new_quantity = current_stock - quantity

      MachineItem.find_by(variant: variant, machine: machine)
                 .update!(stock: new_quantity)
    end
  end
end
