# frozen_string_literal: true

module Avo
  module Resources
    class ContactUsRequest < Avo::BaseResource
      self.title = :full_name
      self.includes = []
      self.search = {
        query: lambda {
          query.ransack(full_name_cont: params[:q], company_name_cont: params[:q], m: 'or').result(distinct: false)
        }
      }

      def fields
        field :id, as: :id
        field :full_name, as: :text, required: true
        field :email, as: :text, required: true, hide_on: :index
        field :phone_number, as: :text, required: true, hide_on: :index
        field :company_name, as: :text
        field :read, as: :boolean, name: 'Read Status'
        field :created_at, as: :text, readonly: true, name: 'Created' do
          record.created_at&.strftime('%d/%m/%y')
        end
        field :updated_at, as: :text, readonly: true, hide_on: :index, name: 'Updated' do
          record.updated_at&.strftime('%d/%m/%y')
        end
      end

      def actions
        action Avo::Actions::ContactUsRequests::MarkAsRead
        action Avo::Actions::ContactUsRequests::MarkAsUnread
      end
    end
  end
end
