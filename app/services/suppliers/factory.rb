# frozen_string_literal: true

module Suppliers
  class Factory
    SUPPLIER_SERVICES = {
      'vendlife' => Suppliers::VendlifeService
    }.freeze

    def self.build(supplier)
      service_class = SUPPLIER_SERVICES[supplier.supplier_type]

      raise UnsupportedSupplierError, "Supplier type '#{supplier.supplier_type}' is not supported" unless service_class

      service_class.new(supplier)
    end

    def self.supported_suppliers
      SUPPLIER_SERVICES.keys
    end
  end
end
