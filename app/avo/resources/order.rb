# frozen_string_literal: true

module Avo
  module Resources
    class Order < Avo::BaseResource
      include ResourceHelpers

      ORDER_EVENTS = ::Order.aasm&.states&.map(&:name)

      self.includes = %i[user machine]
      self.attachments = []
      self.search = {
        query: lambda {
          query.ransack(
            id_eq: params[:q],
            order_number_cont: params[:q],
            user_email_cont: params[:q],
            m: 'or'
          ).result(distinct: false)
        }
      }

      def fields
        field :id, as: :id
        field :number, as: :text, required: true, sortable: true
        field :status, as: :status, enum: ORDER_EVENTS,
                       loading_when: %i[cart initial],
                       success_when: %i[paid dispensed],
                       failed_when: %i[failed canceled],
                       only_on: :display
        field :items_total, as: :text, required: true, sortable: true
        field :user, as: :belongs_to
        field :payment_method, as: :text, name: 'Payment Method' do
          record.payments.last&.payment_method&.name || '—'
        end

        limited_field :machine, as: :belongs_to, searchable: true
        limited_field :user, as: :belongs_to, searchable: true
        field :created_at, as: :date_time, sortable: true
        field :updated_at, as: :date_time, sortable: true

        many_relations
      end

      def many_relations
        tabs id: :many_relations_tabs do
          field :line_items, as: :has_many, reloadable: true, linkable: true, searchable: true
          field :payments, as: :has_many, reloadable: true, linkable: true, searchable: true
        end
      end
    end
  end
end
