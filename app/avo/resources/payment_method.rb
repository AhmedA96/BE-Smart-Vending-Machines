# frozen_string_literal: true

module Avo
  module Resources
    class PaymentMethod < Avo::BaseResource
      self.title = :name
      self.record_selector = false
      self.search = {
        query: -> { query.ransack(name_cont: params[:q], m: 'or').result(distinct: false) }
      }

      def fields
        field :id, as: :id
        field :name, as: :select, options: PAYMENT_METHODS.values
        field :presentation, as: :text
        field :description, as: :text
        field :active, as: :boolean
      end
    end
  end
end
