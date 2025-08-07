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
        field :product, as: :belongs_to, searchable: true, only_on: %i[edit new]
        field :machine, as: :belongs_to, searchable: true
        field :variant, as: :belongs_to, searchable: true
        field :stock, as: :number, required: true, min: 0
        field :line_number, as: :number, required: true, hide_on: :index
        field :created_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
      end
    end
  end
end
