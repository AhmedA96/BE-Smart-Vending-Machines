# frozen_string_literal: true

module LineItems
  class Destroy
    class << self
      def call(line_item)
        order = line_item.order

        ActiveRecord::Base.transaction do
          line_item.destroy!
          order.recalculate_totals!
          order.reload
        end

        order
      end
    end
  end
end
