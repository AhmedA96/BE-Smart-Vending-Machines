# frozen_string_literal: true

module Avo
  module Resources
    class PriceList < Avo::BaseResource
      include ResourceHelpers

      self.title = :name
      self.includes = %i[price_list_items locations]
      self.search = {
        query: -> { query.ransack(name_cont: params[:q], m: 'or').result(distinct: false) }
      }

      def fields
        field :id, as: :id
        field :name, as: :text, searchable: true
        many_relation_tabs
      end

      def many_relation_tabs
        tabs id: :many_relation do
          field :price_list_items, as: :has_many, reloadable: true, searchable: true, linkable: true
          field :locations, as: :has_many, reloadable: true, searchable: true, linkable: true
        end
      end
    end
  end
end
