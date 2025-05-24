# frozen_string_literal: true

module Avo
  module Resources
    class Payment < Avo::BaseResource
      include ResourceHelpers

      self.includes = []
      self.visible_on_sidebar = true
      self.search = {
        query: lambda {
          query.ransack(
            id_eq: params[:q],
            order_number_cont: params[:q],
            payment_method_name_cont: params[:q],
            m: 'or'
          ).result(distinct: false)
        }
      }

      def fields
        payment_events = ::Payment.aasm&.states&.map(&:name)

        field :id, as: :id
        field :amount, as: :number
        field :status, as: :status, enum: payment_events, only_on: :display,
                       loading_when: %i[pending], success_when: %i[completed]
        limited_field :order, as: :belongs_to, searchable: true
        limited_field :payment_method, as: :belongs_to, searchable: true
      end
    end
  end
end
