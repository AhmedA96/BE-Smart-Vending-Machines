# frozen_string_literal: true

module SmsGateway
  class Synapse
    def self.send_sms(mobile_number, message)
      options = {
        body: {
          userName: credentials[:user_name],
          priority: credentials[:priority] || 0,
          msgType: credentials[:msg_type] || 0,
          senderId: credentials[:sender_id],
          message: message,
          mobileNumbers: {
            messageParams: [{ mobileNumber: mobile_number }]
          },
          password: credentials[:password]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      }

      response = HTTParty.post(credentials[:api_endpoint], options)
      response.success? && response.parsed_response['status'] == 'SUCCESS'
    end

    def self.credentials
      Rails.application.credentials.synapse_sms
    end
  end
end
