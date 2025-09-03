# frozen_string_literal: true

module VariantsSheets
  class Columns
    def self.call
      {
        sku: 0,
        name: 1,
        cost_price: 2,
        size: 3,
        weight: 4,
        position: 5,
        active: 6,
        is_master: 7,
        points: 8,
        product_id: 9,
        goods_uuid: 10
      }
    end
  end
end
