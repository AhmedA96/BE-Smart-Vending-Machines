# frozen_string_literal: true

module Suppliers
  module Vendlife
    class BaseClient
      include HTTParty

      attr_reader :supplier, :credentials, :headers

      def initialize(supplier)
        @supplier = supplier
        @credentials = {
          base_url: supplier.base_url,
          app_id: supplier.app_id,
          app_secret: supplier.app_secret
        }

        self.class.base_uri @credentials[:base_url]

        @token = authenticate_and_cache
        @headers = {
          'Content-Type' => 'application/json',
          'Authorization' => @token
        }
      end

      def make_request(method, endpoint, params = {}, body = nil)
        options = { headers: @headers }
        options[:query] = params if params.any?
        options[:body] = body.to_json if body

        attempt_count = 0

        begin
          attempt_count += 1

          response = self.class.send(method, endpoint, options)

          log_api_request(method.to_s.upcase, endpoint, params, response)

          handle_response(response)
        rescue SupplierApiError => e
          if attempt_count == 1 && authentication_error_message?(e.message)
            Rails.logger.warn "Vendlife API: #{method.to_s.upcase} #{endpoint} - " \
                              "authentication error (#{e.message}), refreshing token and retrying once"

            refresh_token!
            options[:headers] = @headers
            retry
          end

          raise
        rescue StandardError => e
          # If, for any reason, a SupplierApiError bubbles into this rescue,
          # re-raise it so we don't double-handle it here.
          raise if e.is_a?(SupplierApiError)

          handle_api_error(e, "#{method} #{endpoint}")
        end
      end

      def refresh_token!
        cache_key = "vendlife_token_#{supplier.id}"
        Rails.cache.delete(cache_key)
        @token = authenticate_with_api
        @headers['Authorization'] = @token
        @token
      end

      def token_valid?
        cache_key = "vendlife_token_#{supplier.id}"
        Rails.cache.exist?(cache_key)
      end

      private

      def authenticate_and_cache
        cache_key = "vendlife_token_#{supplier.id}"
        cached_token = Rails.cache.read(cache_key)
        return cached_token if cached_token

        authenticate_with_api
      end

      def authenticate_with_api
        response = self.class.get('/apiusers/checkusername', {
                                    query: {
                                      userName: @credentials[:app_id],
                                      password: @credentials[:app_secret]
                                    }
                                  })

        if response.parsed_response['result'] == '200'
          token = response.parsed_response['data']
          cache_key = "vendlife_token_#{supplier.id}"
          Rails.cache.write(cache_key, token, expires_in: 6.days)
          token
        else
          error_msg = response.parsed_response['resultDesc'] || 'Authentication failed'
          raise SupplierApiError.new(error_msg, supplier_type: 'vendlife')
        end
      rescue StandardError => e
        raise SupplierApiError.new("Authentication error: #{e.message}", supplier_type: 'vendlife')
      end

      def handle_response(response)
        parsed_response = response.parsed_response

        if parsed_response['result'] == '200'
          parsed_response
        else
          error_msg = parsed_response['resultDesc'] || 'Unknown error'
          raise SupplierApiError.new(error_msg, supplier_type: 'vendlife')
        end
      end

      def authentication_error_message?(message)
        return false if message.nil?

        downcased = message.downcase
        downcased.include?('token 无效') ||
          downcased.include?('token invalid') ||
          downcased.include?('invalid token') ||
          downcased.include?('token expired')
      end

      def log_api_request(method, endpoint, _params, response)
        Rails.logger.info "Vendlife API: #{method} #{endpoint}"
        Rails.logger.error "Vendlife API Error: #{response.code}" if response.code != 200
      end

      def handle_api_error(error, context)
        Rails.logger.error "Vendlife API Error in #{context}: #{error.message}"
        raise SupplierApiError.new(error.message, supplier_type: 'vendlife', context: context)
      end
    end
  end
end
