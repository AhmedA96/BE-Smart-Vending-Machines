# frozen_string_literal: true

module Suppliers
  class VendlifeSupplier < BaseSupplier
    def get_products(page: 1, per_page: 10)
      Vendlife::Products.new(self).list(page: page, per_page: per_page)
    end

    def create_order(options)
      Vendlife::Orders.new(self).create(options)
    end

    def get_order_details(order_no:)
      Vendlife::Orders.new(self).details(order_no: order_no)
    end

    private

    def generate_auth_token
      Rails.cache.fetch("vendlife_token_#{@app_id}", expires_in: 6.days) do
        Rails.logger.info 'Fetching new Vendlife token from API'

        response = HTTParty.get(
          "#{@base_url}/apiusers/checkusername",
          query: {
            userName: @app_id,
            password: @app_secret
          }
        )

        parsed_response = JSON.parse(response.body)
        parsed_response['data']
      end
    end
  end
end
