# frozen_string_literal: true

module Avo
  module Resources
    class Brand < Avo::BaseResource
      self.includes = %i[logo_attachment]
      self.attachments = []

      # Enhanced search with name and description
      self.search = {
        query: lambda {
          query.ransack(
            id_eq: params[:q],
            name_cont: params[:q],
            description_cont: params[:q],
            m: 'or'
          ).result(distinct: false)
        }
      }

      self.title = :name

      def fields
        field :id, as: :id, link_to_record: true

        field :logo, as: :file, is_image: true, link_to_record: true

        field :cover, as: :file, is_image: true, hide_on: %i[index]

        field :name, as: :text, required: true, sortable: true

        field :description, as: :textarea, hide_on: %i[index]

        field :created_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index edit new]

        many_relation_tabs
      end

      def many_relation_tabs
        tabs do
          field :products, as: :has_many, reloadable: true, linkable: true, searchable: true
          field :brand_translations, as: :has_many, reloadable: true, searchable: true, linkable: true
          field :categories, as: :has_many, readonly: true, linkable: true
        end
      end
    end
  end
end
