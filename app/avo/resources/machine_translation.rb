# frozen_string_literal: true

module Avo
  module Resources
    class MachineTranslation < Avo::BaseResource
      self.title = :name
      self.visible_on_sidebar = false
      self.includes = []
      self.search = {
        query: -> { query.ransack(id_eq: params[:q], presentation_cont: params[:q], m: 'or').result(distinct: false) }
      }

      def fields
        field :id, as: :id
        field :name, as: :text
        field :locale, as: :select, options: I18n.available_locales.map(&:to_s), default: I18n.default_locale.to_s
        field :machine, as: :belongs_to
      end
    end
  end
end
