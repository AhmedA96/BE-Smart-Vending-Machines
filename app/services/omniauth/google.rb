# frozen_string_literal: true

module Omniauth
  class Google
    class << self
      def call(params)
        token = params[:token]

        return error_response('Token is required') unless token

        begin
          payload = ::Google::Auth::IDTokens.verify_oidc(
            token,
            aud: ENV.fetch('GOOGLE_CLIENT_ID', nil)
          )

          expected_client_id = ENV.fetch('GOOGLE_CLIENT_ID', nil)
          return error_response('Invalid ID Token audience') unless payload['aud'] == expected_client_id

          return error_response('Email not verified by Google') unless payload['email_verified']

          user = check_or_create_user(payload)
          return error_response('Failed to create user') unless user&.persisted?
        rescue ::Google::Auth::IDTokens::VerificationError
          return error_response('Invalid ID Token')
        rescue ::Google::Auth::IDTokens::ExpiredTokenError
          return error_response('Token is expired')
        rescue StandardError => e
          Rails.logger.error "Google OAuth error: #{e.message}"
          return error_response('Authentication failed')
        end

        success_response(user)
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

      def check_or_create_user(payload)
        user = User.where(provider: 'google', uid: payload['sub']).first_or_initialize do |u|
          u.name = payload['name']
          u.email = payload['email']
          u.password = SecureRandom.base58(12)
          u.avatar_url = payload['picture']
          u.email_verified = payload['email_verified']
        end

        if user.persisted?
          user.update(
            name: payload['name'],
            avatar_url: payload['picture'],
            email_verified: payload['email_verified']
          )
        else
          user.save!(validate: false)
        end

        user
      end

      def user_data(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          avatar_url: user.avatar_url,
          provider: user.provider,
          email_verified: user.email_verified
        }
      end
    end
  end
end
