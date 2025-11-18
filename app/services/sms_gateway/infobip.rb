# frozen_string_literal: true

module SmsGateway
  class Infobip < Base
    def send_sms(mobile_number, message)
      endpoint = "#{credentials[:base_url]}/sms/2/text/advanced"

      body = {
        messages: [
          {
            from: credentials[:sender_id],
            destinations: [
              { to: format_phone_number(mobile_number) }
            ],
            text: message
          }
        ]
      }

      response = make_request(endpoint, body)

      if response[:success]
        log_success(mobile_number, message)
        { success: true, provider: 'infobip', response: response[:body] }
      else
        log_error(mobile_number, response[:message])
        { success: false, provider: 'infobip', error: response[:message] }
      end
    rescue StandardError => e
      log_error(mobile_number, e.message)
      { success: false, provider: 'infobip', error: e.message }
    end

    private

    def credentials
      @credentials ||= {
        api_key: ENV['INFOBIP_API_KEY'] || Rails.application.credentials.dig(:infobip, :api_key),
        sender_id: ENV['INFOBIP_SMS_SENDER'] || Rails.application.credentials.dig(:infobip, :sender_id),
        base_url: ENV['INFOBIP_BASE_URL'] || Rails.application.credentials.dig(:infobip, :base_url)
      }
    end

    def make_request(endpoint, body)
      uri = URI(endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request.body = body.to_json
      request['Authorization'] = "App #{credentials[:api_key]}"
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'

      response = http.request(request)
      parse_response(response)
    end

    def parse_response(response)
      body = JSON.parse(response.body)

      {
        success: response.code.to_i.between?(200, 299),
        status_code: response.code.to_i,
        body: body,
        message: body.dig('requestError', 'serviceException', 'text') ||
          body.dig('messages', 0, 'status', 'description') ||
          'Request completed'
      }
    rescue JSON::ParserError => e
      {
        success: false,
        status_code: 500,
        body: {},
        message: "JSON parsing error: #{e.message}"
      }
    end
  end
end
