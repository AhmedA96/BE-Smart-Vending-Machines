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

        field :stock, as: :number, required: true, min: 0, help: 'Current stock level', hide_on: %i[new edit index]

        field :reserved_stock, as: :number, readonly: true, hide_on: %i[new edit index],
                               help: 'Stock reserved for orders'

        field :available_stock, as: :text, name: 'Available Stock' do
          available = (record.stock.to_i - record.reserved_stock.to_i)

          color, bg_color, text = if available <= 0
                                    ['#ffffff', '#dc2626', 'OUT OF STOCK'] # Red badge
                                  elsif available <= 5
                                    ['#78350f', '#fbbf24', available.to_s]  # Yellow badge
                                  else
                                    ['#065f46', '#22c55e', available.to_s]  # Green badge
                                  end

          "<span style='display: inline-block; padding: 6px 14px; border-radius: 8px;
          background-color: #{bg_color}; color: #{color};
          font-weight: 700; font-size: 16px; text-transform: uppercase;
          box-shadow: 0 1px 3px rgba(0,0,0,0.2);'>
          #{text}
   </span>".html_safe
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
