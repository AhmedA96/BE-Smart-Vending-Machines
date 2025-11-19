# frozen_string_literal: true

module Notifications
  class Create
    def initialize(user:, attributes:)
      @user = user
      @attributes = attributes.symbolize_keys
    end

    def call
      validate_type!

      notification = Notification.create!(
        user: @user,
        notifiable: @attributes[:notifiable],
        notification_type: @attributes[:type],
        translation_key: @attributes[:translation_key],
        translation_params: @attributes[:translation_params] || {},
        title: generate_title(I18n.default_locale),
        body: generate_body(I18n.default_locale),
        metadata: @attributes[:metadata] || {}
      )

      Notifications::PushJob.perform_later(notification.id)

      notification
    end

    private

    def validate_type!
      type = @attributes[:type]
      return if Notification::TYPES.value?(type)

      raise ArgumentError, "Invalid notification type: #{type.inspect}"
    end

    def generate_title(locale)
      key = @attributes[:translation_key]
      params = resolved_translation_params(locale)

      I18n.t("#{key}.title", **params, locale: locale)
    rescue I18n::MissingTranslationData => e
      Rails.logger.error("Missing translation for #{key}.title: #{e.message}")
      'Notification'
    end

    def generate_body(locale)
      key = @attributes[:translation_key]
      params = resolved_translation_params(locale)

      I18n.t("#{key}.body", **params, locale: locale)
    rescue I18n::MissingTranslationData => e
      Rails.logger.error("Missing translation for #{key}.body: #{e.message}")
      'You have a new notification'
    end

    def resolved_translation_params(locale)
      params = (@attributes[:translation_params] || {}).symbolize_keys

      return if params[:machine_id].blank?

      machine = Machine.find_by(id: params[:machine_id])
      params[:machine_name] =
        Mobility.with_locale(locale) { machine.name }

      params
    end
  end
end
