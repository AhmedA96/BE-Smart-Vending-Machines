# frozen_string_literal: true

module Avo
  module Resources
    class BrandTranslation < Avo::BaseResource
      self.visible_on_sidebar = false
      self.search = {
        query: lambda {
          query.ransack(presentation_cont: params[:q], m: 'or').result(distinct: true)
        },
        item: lambda {
          {
            title: "#{record.presentation} (#{record.id})"
          }
        },
        help: -> { '- Search by presentation' }
      }

      self.title = :presentation
      self.includes = [:brand]

      def fields
        field :id, as: :id
        field :presentation, as: :text
        field :description, as: :textarea
        field :locale, as: :select, options: I18n.available_locales.map(&:to_s), default: I18n.default_locale.to_s
        field :brand, as: :belongs_to
      end
    end
  end
end
