# frozen_string_literal: true

module Avo
  module Resources
    class MachineItem < Avo::BaseResource
      include ResourceHelpers

      self.title = :id
      self.includes = %i[machine variant product]
      self.visible_on_sidebar = true

      def self.plural_name
        'STOCK MANAGEMENT'
      end

      self.search = {
        query: lambda {
          query.ransack(
            id_eq: params[:q],
            product_name_or_variant_name_cont: params[:q],
            machine_name_cont: params[:q],
            m: 'or'
          ).result(distinct: false)
        }
      }

      def fields
        field :id, as: :id

        field :machine, as: :belongs_to, searchable: true

        field :variant_name, as: :text, only_on: :index do
          record.variant&.name
        end

        field :product, as: :has_one, through: :variant, readonly: true, hide_on: %i[new edit index]

        field :stock, as: :number, required: true, min: 0, help: 'Current stock level'

        field :reserved_stock, as: :number, readonly: true, hide_on: %i[new edit],
                               help: 'Stock reserved for orders'

        field :available_stock, as: :text, hide_on: %i[new edit] do
          record.stock - record.reserved_stock
        end

        field :line_number, as: :number, required: true, hide_on: :index,
                            help: 'Position in vending machine aisle'

        field :created_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
      end

      def filters
        filter Avo::Filters::MachineItems::MachineFilter
        filter Avo::Filters::MachineItems::LowStockFilter
      end

      def actions
        action Avo::Actions::MachineItems::SyncInventory
      end

      self.index_query = lambda {
        query.includes(:machine, :variant, :product).order('machines.name ASC, line_number ASC')
      }
    end
  end
end
