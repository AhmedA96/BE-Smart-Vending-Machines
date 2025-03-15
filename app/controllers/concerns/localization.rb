# frozen_string_literal: true

module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  def switch_locale(&)
    I18n.locale = request_locale
    Mobility.with_locale(I18n.locale, &)
  end

  private

  def request_locale
    accept_language = locale_from_header
    valid_locale?(accept_language) ? accept_language : default_locale
  end

  def locale_from_header
    language_header = request.headers['Accept-Language']
    language_header&.scan(/^[a-z]{2}(?:-[A-Z]{2})?/)&.first&.to_sym
  end

  def valid_locale?(locale)
    Mobility.available_locales.include?(locale)
  end

  def default_locale
    :en
  end
end
