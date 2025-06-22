# frozen_string_literal: true

module Avo
  module Actions
    module ContactUsRequests
      class MarkAsUnread < Avo::BaseAction
        self.name = 'Mark as unread'
        self.no_confirmation = true

        def handle(records:, **_args)
          records.each do |record|
            record.update(read: false)
          end

          succeed "Marked #{records.count} #{records.one? ? 'request' : 'requests'} as unread."
        end
      end
    end
  end
end
