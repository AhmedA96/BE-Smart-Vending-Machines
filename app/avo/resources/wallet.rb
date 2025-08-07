# frozen_string_literal: true

module Avo
  module Resources
    class Wallet < Avo::BaseResource
      include ResourceHelpers

      self.includes = %i[]
      self.title = -> { "#{record.user&.email} " }
      self.search = {
        query: lambda {
          query.ransack(id_eq: params[:q], user_name_cont: params[:q], user_email_cont: params[:q],
                        m: 'or').result(distinct: false)
        },
        item: lambda {
          {
            title: record.user&.email.to_s,
            description: "Balance: #{record.balance} - Total: #{record.total}"
          }
        },
        help: -> { 'Search by reason' }
      }

      def fields
        field :id, as: :id
        field :balance, as: :number, required: true, only_on: %i[index show]
        limited_field :user, as: :belongs_to, searchable: true
      end
    end
  end
end
