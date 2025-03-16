# frozen_string_literal: true

module Avo
  module Resources
    class User < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
      # }
      def fields
        field :id, as: :id
        field :email, as: :text
        field :date_of_birth, as: :date
        field :locale, as: :text
        field :mobile_number, as: :text
        field :verified, as: :boolean
        field :last_active_at, as: :date_time
        field :deleted_at, as: :date_time
        field :membership_number, as: :text
        field :name, as: :text
        field :created_at, as: :date_time
      end
    end
  end
end
