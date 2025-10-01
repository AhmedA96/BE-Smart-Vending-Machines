# frozen_string_literal: true

module Orders
  class CheckOrderStatus
    def self.call(order)
      supplier = order.machine.supplier
      service = service_for_supplier(supplier)
      service.get_order_status(order.number)
    rescue StandardError => e
      Rails.logger.error "[CheckOrderStatus] Failed to fetch status for order #{order.number}: #{e.message}"
      raise SupplierApiError.new('Failed to check order status', supplier_type: supplier&.supplier_type,
                                                                 context: 'order_status')
    end

    def self.service_for_supplier(supplier)
      case supplier.supplier_type
      when 'vendlife'
        Suppliers::VendlifeService.new(supplier)
      else
        raise ArgumentError, "Unsupported supplier type: #{supplier.supplier_type}"
      end
    end
  end
end
