# frozen_string_literal: true

module Avo
  module Filters
    module Orders
      class OrderStatusFilter < Avo::Filters::SelectFilter
        self.name = 'Status'
        self.visible = -> { true }

        def apply(_request, query, value)
          case value
          when 'all_completed'
            query.where(status: %w[completed dispensed])
          else
            query.where(status: value)
          end
        end

        def options
          {
            'cart' => 'Cart',
            'payment' => 'Payment',
            'completed' => 'Completed',
            'dispensed' => 'Dispensed'
          }
        end

        def default
          nil
        end
      end
    end
  end
end
