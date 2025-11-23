# frozen_string_literal: true

module Avo
  module Actions
    module Orders
      class ExportOrder < Avo::BaseAction
        self.name = 'Export as CSV'
        self.no_confirmation = false
        self.message = 'Export this order to CSV?'

        def handle(records:, **_args)
          return succeed('Please select at least one order') if records.blank?

          generate_csv(records)

          succeed "Export ready for #{records.count} order(s). Download started."
        end

        private

        def generate_csv(records)
          require 'csv'

          CSV.generate(headers: true) do |csv|
            csv << ['Order #', 'Customer Email', 'Machine', 'Status', 'Items Total', 'Total', 'Created At']

            records.each do |order|
              csv << [
                order.number,
                order.user&.email || 'Guest',
                order.machine&.name,
                order.status.titleize,
                order.items_total,
                order.total,
                order.created_at.strftime('%Y-%m-%d %H:%M')
              ]
            end
          end
        end
      end
    end
  end
end
