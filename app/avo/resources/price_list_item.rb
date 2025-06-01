# frozen_string_literal: true

module Avo
  module Resources
    class PriceListItem < Avo::BaseResource
      include ResourceHelpers

      self.includes = []
      self.visible_on_sidebar = false
      self.search = {
        query: lambda {
          query.ransack(variant_sku_or_variant_name_or_variant_product_name_cont: params[:q],
                        m: 'or').result(distinct: false)
        },
        item: lambda {
                {
                  title: record&.variant&.name.to_s,
                  description: "#{record.price} - #{record&.price_list}"
                }
              },
        help: -> { 'Search by name/sku' }
      }

      def fields
        field :id, as: :id
        field :price, as: :number
        field :variant, as: :belongs_to
        limited_field :price_list, as: :belongs_to, searchable: true
      end
    end
  end
end
