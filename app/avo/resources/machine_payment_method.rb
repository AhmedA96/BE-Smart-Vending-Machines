# frozen_string_literal: true

module Avo
  module Resources
    class MachinePaymentMethod < Avo::BaseResource
      include ResourceHelpers
      self.includes = []
      self.visible_on_sidebar = false

      def fields
        field :id, as: :id
        field :active, as: :boolean
        field :payment_method, as: :belongs_to
      end
    end
  end
end
