# frozen_string_literal: true

module SmsGateway
  class Synapse < Base
    def send_sms(mobile_number, message)
      options = {
        body: {
          userName: credentials[:user_name],
          priority: credentials[:priority] || 0,
          msgType: credentials[:msg_type] || 0,
          senderId: credentials[:sender_id],
          message: message,
          mobileNumbers: {
            messageParams: [{ mobileNumber: format_phone_number(mobile_number) }]
          },
          password: credentials[:password]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      }

      response = HTTParty.post(credentials[:api_endpoint], options)

      if response.success? && response.parsed_response['status'] == 'SUCCESS'
        log_success(mobile_number, message)
        { success: true, provider: 'synapse', response: response.parsed_response }
      else
        error_message = response.parsed_response['message'] || 'Unknown error'
        log_error(mobile_number, error_message)
        { success: false, provider: 'synapse', error: error_message }
      end
    rescue StandardError => e
      log_error(mobile_number, e.message)
      { success: false, provider: 'synapse', error: e.message }
    end

    private

    def credentials
      @credentials ||= Rails.application.credentials.synapse_sms
    end
  end
end
