# frozen_string_literal: true

module Omniauth
  class Apple
    APPLE_ISSUER = 'https://appleid.apple.com'
    APPLE_KEYS_URL = 'https://appleid.apple.com/auth/keys'

    class << self
      def call(params)
        token = params[:token]
        user_data = params[:user]

        return error_response('Token is required') unless token

        begin
          payload = verify_apple_token(token)
          return error_response('Invalid Apple ID Token') unless payload

          user = check_or_create_user(payload, user_data)
          return error_response('Failed to create user') unless user&.persisted?
        rescue JWT::ExpiredSignature
          error_response('Apple ID Token is expired')
        rescue JWT::DecodeError, JWT::VerificationError
          error_response('Invalid Apple ID Token')
        rescue StandardError => e
          Rails.logger.error "Apple OAuth error: #{e.message}"
          error_response('Authentication failed')
        else
          success_response(user)
        end
      end

      def verify_apple_token(token)
        response = HTTParty.get(APPLE_KEYS_URL)
        return nil unless response.code == 200

        keys = response.parsed_response['keys']
        header = JWT.decode(token, nil, false)[1]
        kid = header['kid']

        key_data = keys.find { |key| key['kid'] == kid }
        return nil unless key_data

        jwk = JWT::JWK.import(key_data)

        decoded_token = JWT.decode(
          token,
          jwk.public_key,
          true,
          {
            algorithm: 'RS256',
            iss: APPLE_ISSUER,
            aud: ENV.fetch('APPLE_CLIENT_ID', nil),
            verify_iss: true,
            verify_aud: true,
            verify_iat: true,
            verify_exp: true
          }
        )

        decoded_token[0]
      end

      def check_or_create_user(payload, user_data = nil)
        apple_id = payload['sub']
        email = payload['email']
        verified = payload['email_verified'].to_s == 'true'

        user = User.where(provider: 'apple', uid: apple_id).first_or_initialize do |u|
          u.email = email
          u.name = extract_name_from_user_data(user_data) || email&.split('@')&.first
          u.password = SecureRandom.base58(12)
          u.email_verified = verified
        end

        if user.persisted?
          updates = { email_verified: verified }
          updates[:name] = extract_name_from_user_data(user_data) if user_data.present?
          user.update(updates)
        else
          user.save!(validate: false)
        end

        user
      end

      def extract_name_from_user_data(user_data)
        return if user_data.blank?

        parsed_data = user_data.is_a?(String) ? JSON.parse(user_data) : user_data
        name = parsed_data['name']
        "#{name['firstName']} #{name['lastName']}".strip if name
      rescue JSON::ParserError
        nil
      end

      def success_response(user)
        auth = Doorkeeper::AccessToken.create!(
          resource_owner: user,
          expires_in: 24.hours,
          scopes: 'read write'
        )

        {
          success: true,
          access_token: auth.token,
          token_type: 'Bearer',
          refresh_token: auth.refresh_token,
          expires_in: auth.expires_in,
          created_at: auth.created_at.to_i,
          user: user_data(user)
        }
      end

      def error_response(message)
        { success: false, error: message }
      end

      def user_data(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          provider: user.provider,
          email_verified: user.email_verified
        }
      end
    end
  end
end
