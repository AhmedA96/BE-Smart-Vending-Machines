# frozen_string_literal: true

module Avo
  module Resources
    class Variant < Avo::BaseResource
      include ResourceHelpers

      self.title = :full_name
      self.includes = []
      self.visible_on_sidebar = false
      self.search = {
        query: lambda {
          query.ransack(name_cont: params[:q], sku_cont: params[:q],
                        m: 'or').result(distinct: true)
        },
        item: lambda {
          {
            title: "#{record&.name} - #{record&.sku}"
          }
        },
        help: -> { 'Search by variant' }
      }

      def fields
        field :id, as: :id
        field :name, as: :text
        field :sku, as: :text
        field :is_master, as: :boolean
        field :points, as: :number, only_on: %i[index show]
        field :weight, as: :number
        field :position, as: :number
        field :active, as: :boolean, readonly: -> { resource.record.is_master? }, filterable: true
        limited_field :product, as: :belongs_to, searchable: true
      end
    end
  end
end
