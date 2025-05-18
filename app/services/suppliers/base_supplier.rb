# frozen_string_literal: true

module Suppliers
  class BaseSupplier
    attr_reader :app_id, :app_secret, :machine_no, :base_url, :auth_token

    def initialize(supplier, machine_external_id)
      @app_id = supplier.app_id
      @app_secret = supplier.app_secret
      @machine_no = machine_external_id
      @base_url = supplier.base_url
      @auth_token = generate_auth_token
    end

    private

    def generate_auth_token
      Base64.strict_encode64("#{@app_id}:#{@app_secret}")
    end

    def get_products(**options)
      raise NotImplementedError, 'Subclasses must implement get_products'
    end

    def create_order(**options)
      raise NotImplementedError, 'Subclasses must implement create_order'
    end

    def get_order_details(**options)
      raise NotImplementedError, 'Subclasses must implement get_order_details'
    end
  end
end
