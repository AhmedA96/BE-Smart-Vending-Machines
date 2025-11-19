# frozen_string_literal: true

module SmsGateway
  class Base
    class SendError < StandardError; end

    def send_sms(mobile_number, message)
      raise NotImplementedError, 'Subclasses must implement send_sms method'
    end

    protected

    def format_phone_number(mobile_number)
      mobile_number.to_s.gsub(/\D/, '')
    end

    def log_success(mobile_number, message)
      Rails.logger.info("SMS sent successfully to #{mobile_number}: #{message}")
    end

    def log_error(mobile_number, error)
      Rails.logger.error("SMS failed to #{mobile_number}: #{error}")
    end
  end
end
