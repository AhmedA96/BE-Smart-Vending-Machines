# frozen_string_literal: true

module Avo
  module Resources
    class CountryTranslation < Avo::BaseResource
      include ResourceHelpers

      self.visible_on_sidebar = false
      self.search = {
        query: -> { query.ransack(name_eq: params[:q], m: 'or').result(distinct: false) }
      }

      def fields
        field :id, as: :id
        field :presentation, as: :text
        field :locale, as: :select, options: I18n.available_locales.map(&:to_s), default: I18n.default_locale.to_s
        field :currency, as: :text, readonly: true
        limited_field :country, as: :belongs_to, searchable: true
      end
    end
  end
end
