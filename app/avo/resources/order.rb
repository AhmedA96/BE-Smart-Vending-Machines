# frozen_string_literal: true

module Avo
  module Resources
    class Order < Avo::BaseResource
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
        field :order_number, as: :text, required: true, sortable: true
        field :status, as: :select, options: {
          pending: 'Pending',
          processing: 'Processing',
          completed: 'Completed',
          cancelled: 'Cancelled'
        }, required: true

        field :total_amount, as: :currency, required: true
        field :user, as: :belongs_to
        field :payment_method, as: :select, options: {
          credit_card: 'Credit Card',
          paypal: 'PayPal',
          bank_transfer: 'Bank Transfer'
        }

        field :created_at, as: :date_time, sortable: true
        field :updated_at, as: :date_time, sortable: true
      end
    end
  end
end
