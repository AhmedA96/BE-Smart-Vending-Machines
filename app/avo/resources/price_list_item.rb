# frozen_string_literal: true

module Avo
  module Resources
    class PriceListItem < Avo::BaseResource
      include ResourceHelpers

      self.includes = []
      self.search = {
        query: lambda {
          query.ransack(variant_sku_or_variant_name_or_variant_product_name_cont: params[:q],
                        m: 'or').result(distinct: false)
        },
        item: lambda {
                record.owner.class.name
                {
                  title: "#{record&.product&.name} #{record&.name == record&.product&.name ? '' : record&.name} [#{record.owner.sku}]", # rubocop:disable Layout/LineLength
                  description: "#{record.price} - #{record&.price_list}"
                }
              },
        help: -> { 'Search by name/sku' }
      }

      def fields
        field :id, as: :id
        field :price, as: :number
        limited_field :price_list, as: :belongs_to, searchable: true
      end
    end
  end
end
