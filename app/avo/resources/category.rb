# frozen_string_literal: true

module Avo
  module Resources
    class Category < Avo::BaseResource
      self.includes = %i[logo_attachment]
      self.attachments = []
      self.title = :name
      self.default_sort_column = :position
      self.default_sort_direction = :asc
      self.default_view_type = :grid

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

      def fields
        field :id, as: :id, link_to_record: true

        field :logo, as: :file, is_image: true, link_to_record: true

        field :name, as: :text, required: true, sortable: true

        field :presentation, as: :text, required: true, hide_on: %i[index]

        field :description, as: :textarea, hide_on: %i[index]

        field :position, as: :number, default: 0, hide_on: %i[index]

        field :active, as: :boolean, default: true, hide_on: %i[index]

        field :created_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index edit new]

        many_relation_tabs
      end

      def many_relation_tabs
        tabs do
          field :products, as: :has_many, reloadable: true, linkable: true, searchable: true
          field :category_translations, as: :has_many, reloadable: true, searchable: true, linkable: true
        end
      end
    end
  end
end
