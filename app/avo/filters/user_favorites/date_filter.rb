# frozen_string_literal: true

module Avo
  module Filters
    module UserFavorites
      class DateFilter < Avo::Filters::SelectFilter
        self.name = 'Date Range'

        def apply(_request, query, value)
          case value.to_s
          when 'today'
            query.where(created_at: Date.current.all_day)
          when 'this week'
            query.where(created_at: Date.current.all_week)
          when 'this month'
            query.where(created_at: Date.current.all_month)
          else
            query
          end
        end

        def options
          {
            'Today' => 'Today',
            'This Week' => 'This Week',
            'This Month' => 'This Month'
          }
        end
      end
    end
  end
end
