# frozen_string_literal: true

module LineItems
  class Destroy
    class << self
      def call(line_item)
        order = line_item.order

        ActiveRecord::Base.transaction do
          Stock::Management.call(
            line_item.variant_id,
            -line_item.quantity,
            line_item.order.machine.id
          )

          line_item.destroy!
          order.recalculate_totals!
          order.reload
        end

        order
      end
    end
  end
end
