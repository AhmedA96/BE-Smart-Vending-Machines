# frozen_string_literal: true

module LineItems
  class Update
    class << self
      def call(line_item, item_params)
        new_quantity = item_params[:quantity].to_i
        order = line_item.order

        ActiveRecord::Base.transaction do
          if new_quantity.zero?
            line_item.destroy!
          else
            line_item.update!(quantity: quantity)
          end

          order.recalculate_totals!
          order.reload
        end

        order
      end
    end
  end
end
