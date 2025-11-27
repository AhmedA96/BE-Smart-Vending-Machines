# frozen_string_literal: true

module Avo
  module Filters
    module MachineItems
      class MachineFilter < Avo::Filters::SelectFilter
        self.name = 'Machine'

        def apply(_request, query, value)
          return query if value.blank?

          query.where(machine_id: value)
        end

        def options
          # Return hash format: { id => "Display Label" }
          # The KEY is the value used for filtering, the VALUE is what displays
          Machine.order(:name).pluck(:id, :name).to_h
        end
      end
    end
  end
end
