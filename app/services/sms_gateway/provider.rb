# frozen_string_literal: true

module SmsGateway
  class Provider
    PROVIDERS = {
      synapse: Synapse,
      infobip: Infobip
    }.freeze

    class << self
      def send_sms(mobile_number, message, provider_name = nil)
        provider_name ||= default_provider
        provider_class = PROVIDERS[provider_name.to_sym]

        raise ArgumentError, "Unknown SMS provider: #{provider_name}" unless provider_class

        provider_class.new.send_sms(mobile_number, message)
      end

      def default_provider
        (ENV['SMS_PROVIDER'] || Rails.application.credentials.dig(:sms, :default_provider) || 'infobip').to_sym
      end

      def available_providers
        PROVIDERS.keys
      end
    end
  end
end
