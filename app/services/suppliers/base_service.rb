# frozen_string_literal: true

module Suppliers
  class BaseService
    attr_reader :supplier

    def initialize(supplier)
      @supplier = supplier
      validate_supplier!
    end

    # ==================== AUTHENTICATION INTERFACE ====================

    def authenticate
      raise NotImplementedError, "#{self.class} must implement #authenticate"
    end

    def refresh_token!
      raise NotImplementedError, "#{self.class} must implement #refresh_token!"
    end

    def token_valid?
      raise NotImplementedError, "#{self.class} must implement #token_valid?"
    end

    # ==================== MACHINE INTERFACE ====================

    def get_machines(machineuuid = nil)
      raise NotImplementedError, "#{self.class} must implement #get_machines"
    end

    def get_machine_status(machineuuid)
      raise NotImplementedError, "#{self.class} must implement #get_machine_status"
    end

    def sync_machine_data(machine)
      raise NotImplementedError, "#{self.class} must implement #sync_machine_data"
    end

    # ==================== INVENTORY INTERFACE ====================

    def get_inventory(machineuuid = nil)
      raise NotImplementedError, "#{self.class} must implement #get_inventory"
    end

    def sync_inventory(machine)
      raise NotImplementedError, "#{self.class} must implement #sync_inventory"
    end

    def update_inventory(machine, inventory_data)
      raise NotImplementedError, "#{self.class} must implement #update_inventory"
    end

    # ==================== PRODUCT INTERFACE ====================

    def get_products(machineuuid = nil)
      raise NotImplementedError, "#{self.class} must implement #get_products"
    end

    def sync_products(machine)
      raise NotImplementedError, "#{self.class} must implement #sync_products"
    end

    # ==================== DISPENSING INTERFACE ====================

    def dispense_product(machine, order)
      raise NotImplementedError, "#{self.class} must implement #dispense_product"
    end

    def create_pickup_order(machine, order)
      raise NotImplementedError, "#{self.class} must implement #create_pickup_order"
    end

    def cancel_pickup_order(pickup_code)
      raise NotImplementedError, "#{self.class} must implement #cancel_pickup_order"
    end

    # ==================== ORDER TRACKING INTERFACE ====================

    def get_orders(start_time:, end_time:, machineuuid: nil, **options)
      raise NotImplementedError, "#{self.class} must implement #get_orders"
    end

    def get_order_status(order_reference)
      raise NotImplementedError, "#{self.class} must implement #get_order_status"
    end

    def sync_orders(machine, start_time:, end_time:)
      raise NotImplementedError, "#{self.class} must implement #sync_orders"
    end

    # ==================== STATISTICS INTERFACE ====================

    def get_sales_statistics(start_time:, end_time:, machine_id: nil, **options)
      raise NotImplementedError, "#{self.class} must implement #get_sales_statistics"
    end

    # ==================== CONFIGURATION INTERFACE ====================

    def get_machine_configuration(machineuuid)
      raise NotImplementedError, "#{self.class} must implement #get_machine_configuration"
    end

    def update_machine_configuration(machineuuid, config)
      raise NotImplementedError, "#{self.class} must implement #update_machine_configuration"
    end

    # ==================== COMMON HELPER METHODS ====================

    def supported_features
      {
        authentication: true,
        machine_management: true,
        inventory_management: true,
        product_management: true,
        dispensing: true,
        order_tracking: true,
        statistics: true,
        configuration: true
      }
    end

    def supplier_type
      self.class.name.demodulize.gsub('Service', '').downcase
    end

    protected

    def validate_supplier!
      raise ArgumentError, 'Supplier cannot be nil' unless supplier
      raise ArgumentError, 'Invalid supplier type' unless valid_supplier_type?
    end

    def valid_supplier_type?
      supplier.supplier_type == supplier_type
    end

    def log_api_request(method, endpoint, _params = {}, _response = nil, error = nil)
      Rails.logger.info "#{supplier_type.upcase} API: #{method} #{endpoint}"
      Rails.logger.error "#{supplier_type.upcase} API Error: #{error}" if error
    end

    def handle_api_error(error, context = nil)
      Rails.logger.error "#{supplier_type.upcase} API Error in #{context}: #{error.message}"
      raise SupplierApiError.new(error.message, supplier_type: supplier_type, context: context)
    end

    def generate_order_number(prefix = nil)
      prefix ||= supplier_type.upcase
      "#{prefix}_#{supplier.id}_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
    end

    def parse_datetime(datetime_string)
      return nil if datetime_string.blank?

      Time.zone.parse(datetime_string)
    rescue ArgumentError
      nil
    end
  end
end
