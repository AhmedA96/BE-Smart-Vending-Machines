# frozen_string_literal: true

module Avo
  module Actions
    module Orders
      class RefundOrder < Avo::BaseAction
        self.name = 'Refund Order'
        self.no_confirmation = false
        self.message = 'Are you sure you want to refund this order?'

        def handle(records:, **_args)
          return succeed('Please select at least one order') if records.blank?

          refunded_count = 0
          records.each do |order|
            next unless order.status.in?(%w[completed dispensed])

            begin
              # Call refund service
              Orders::RefundOrder.call(order)
              refunded_count += 1
            rescue StandardError => e
              Rails.logger.error("Refund failed for order #{order.number}: #{e.message}")
            end
          end

          if refunded_count.positive?
            succeed "#{refunded_count} order(s) refunded successfully."
          else
            error 'No eligible orders to refund.'
          end
        end
      end
    end
  end
end
