# frozen_string_literal: true

module Avo
  module Resources
    class Category < Avo::BaseResource
      self.title = :name
      self.includes = %i[products translations]
      self.default_sort_column = :position
      self.default_sort_direction = :asc
      self.default_view_type = :grid
      self.search = {
        query: -> { query.ransack(name_cont: params[:q], m: 'or').result(distinct: false) },
        item: lambda {
                {
                  title: record&.name&.to_s,
                  description: "Contains #{record.products.count} products"
                }
              },
        help: -> { 'Search by category' }
      }

      def fields
        field :id, as: :id
        field :name, as: :text, required: true
        field :position, as: :number, default: 0, hide_on: %i[index]
        field :active, as: :boolean, default: true, hide_on: %i[index]
        field :created_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index edit new]

        many_relation_tabs
      end

      def many_relation_tabs
        tabs id: :many_relations do
          field :products, as: :has_many, reloadable: true, linkable: true
          field :category_translations, as: :has_many, reloadable: true, linkable: true
        end
      end
    end
  end
end
