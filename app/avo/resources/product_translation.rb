# frozen_string_literal: true

module Avo
  module Resources
    class ProductTranslation < Avo::BaseResource
      include ResourceHelpers

      self.title = :presentation
      self.visible_on_sidebar = false
      self.includes = []
      self.search = {
        query: -> { query.ransack(presentation_eq: params[:q], m: 'or').result(distinct: false) }
      }

      def fields
        field :id, as: :id
        field :presentation, as: :text
        field :description, as: :textarea
        field :locale, as: :select, options: I18n.available_locales.map(&:to_s), default: I18n.default_locale.to_s
        field :product, as: :belongs_to
      end
    end
  end
end
