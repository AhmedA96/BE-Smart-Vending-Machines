# frozen_string_literal: true

require 'googleauth'
require 'net/http'
require 'json'

module Firebase
  class PushService
    FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'

    def initialize
      @project_id = fetch(:project_id)
      @client_email = fetch(:client_email)
      @private_key = fetch(:private_key)
      @token_uri = fetch(:token_uri)
    end

    def send_notification(device_token:, title:, body:, data: {})
      token = fetch_access_token

      safe_data = data.transform_values(&:to_s)

      uri = URI("https://fcm.googleapis.com/v1/projects/#{@project_id}/messages:send")
      payload = {
        message: {
          token: device_token,
          notification: { title: title, body: body },
          data: safe_data
        }
      }

      response = Net::HTTP.post(uri, payload.to_json, {
                                  'Authorization' => "Bearer #{token}",
                                  'Content-Type' => 'application/json'
                                })

      Rails.logger.info("[FCM v1] #{response.code} #{response.body}")

      response.code == '200'
    rescue StandardError => e
      Rails.logger.error("[FCM v1] Push failed: #{e.class} - #{e.message}")
      false
    end

    private

    def fetch_access_token
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(service_account_json.to_json),
        scope: FCM_SCOPE
      )
      authorizer.fetch_access_token!['access_token']
    end

    def service_account_json
      {
        'type' => 'service_account',
        'project_id' => @project_id,
        'private_key' => format_private_key(@private_key),
        'client_email' => @client_email,
        'token_uri' => @token_uri
      }
    end

    def fetch(key, default = nil)
      Rails.application.credentials.dig(:firebase, key) ||
        ENV["FIREBASE_#{key.to_s.upcase}"] ||
        default
    end

    def format_private_key(key)
      key.to_s.gsub('\n', "\n")
    end
  end
end
