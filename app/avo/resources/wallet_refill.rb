# frozen_string_literal: true

module Avo
  module Resources
    class WalletRefill < Avo::BaseResource
      include ResourceHelpers

      self.title = :resource_title
      self.includes = %i[user_wallet payment_method]
      self.visible_on_sidebar = false

      self.search = {
        query: lambda {
          query
            .joins(user_wallet: :user)
            .ransack(
              status_cont: params[:q],
              user_wallet_user_name_cont: params[:q],
              user_wallet_user_email_cont: params[:q],
              m: 'or'
            ).result(distinct: false)
        },
        item: lambda {
          {
            title: "#{record.resource_title} - (#{record.status})",
            description: "(#{record.user_name.presence || record.user_email})
              - #{record.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
          }
        },
        help: -> { 'Search by status, user name or user email' }
      }

      def fields
        field :id, as: :id
        field :amount, as: :number, filterable: true
        field :card_id, as: :number, format_using: lambda {
          if view.form?
            value
          else
            '*' * value.to_s.length
          end
        }
        field :token_id, as: :text, format_using: lambda {
          if view.form?
            value
          else
            '*' * value.to_s.length
          end
        }
        field :status, as: :text, filterable: true
        field :created_at, as: :date_time, filterable: true

        one_relation_tabs
      end

      private

      def one_relation_tabs
        tabs id: :one_relation_tabs do
          limited_field :user_wallet, as: :belongs_to, searchable: true
          limited_field :payment_method, as: :belongs_to, searchable: true
        end
      end
    end
  end
end
