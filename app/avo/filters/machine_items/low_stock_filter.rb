# frozen_string_literal: true

module Avo
  module Filters
    module MachineItems
      class LowStockFilter < Avo::Filters::BooleanFilter
        self.name = 'Stock Status'

        def apply(_request, query, values)
          # values comes with STRINGIFIED keys in Avo 3.x
          query = query.where(stock: ..5) if values['low_stock']

          query = query.where(stock: 0) if values['out_of_stock']

          query = query.where('reserved_stock > ?', 0) if values['has_reserved']

          query
        end

        def options
          {
            low_stock: 'LOW STOCK(≤5)',
            out_of_stock: 'OUT OF STOCK',
            has_reserved: 'HAS RESERVED STOCK'
          }
        end
      end
    end
  end
end
