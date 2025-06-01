# frozen_string_literal: true

module Avo
  module Resources
    class Brand < Avo::BaseResource
      self.includes = %i[products translations]
      self.attachments = []

      self.search = {
        query: -> { query.ransack(id_eq: params[:q], m: 'or').result(distinct: false) }
      }

      def fields
        field :id, as: :id
        field :name, as: :text, required: true
        field :description, as: :textarea, hide_on: %i[index]
        field :logo, as: :file, hide_on: %i[index]
        field :created_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index edit new]

        many_relation_tabs
      end

      def many_relation_tabs
        tabs id: :many_relations_tabs do
          field :products, as: :has_many, reloadable: true, linkable: true, searchable: true
          field :brand_translations, as: :has_many, reloadable: true, searchable: true, linkable: true
        end
      end
    end
  end
end
