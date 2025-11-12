# frozen_string_literal: true

module Avo
  module Resources
    class MachineItem < Avo::BaseResource
      include ResourceHelpers

      self.includes = []
      self.visible_on_sidebar = false

      self.search = {
        query: lambda {
          query.ransack(id_eq: params[:q], product_name_or_variant_name_cont: params[:q],
                        m: 'or').result(distinct: false)
        }
      }

      def fields
        field :id, as: :id
        field :machine, as: :belongs_to, searchable: true
        field :variant, as: :belongs_to, searchable: true
        field :stock, as: :number, required: true, min: 0
        field :reserved_stock, as: :number, readonly: true
        field :line_number, as: :number, required: true
        field :created_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
      end
    end
  end
end
