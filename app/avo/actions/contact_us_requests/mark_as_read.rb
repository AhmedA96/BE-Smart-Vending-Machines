# frozen_string_literal: true

module Avo
  module Actions
    module ContactUsRequests
      class MarkAsRead < Avo::BaseAction
        self.name = 'Mark as read'
        self.no_confirmation = true

        def handle(records:, **_args)
          records.each do |record|
            record.update(read: true)
          end

          succeed "Marked #{records.count} #{records.count == 1 ? 'request' : 'requests'} as read."
        end
      end
    end
  end
end
