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
        field :avatar, as: :text
        field :date_of_birth, as: :date
        field :gender, as: :text
        field :nationality, as: :text
        field :locale, as: :text
        field :mobile_number, as: :text
        field :verified, as: :boolean
        field :last_active_at, as: :date_time
        field :deleted_at, as: :date_time
        field :membership_number, as: :text
        field :sign_in_count, as: :number
        field :current_sign_in_at, as: :date_time
        field :last_sign_in_at, as: :date_time
        field :current_sign_in_ip, as: :text
        field :last_sign_in_ip, as: :text
        field :confirmation_token, as: :text
        field :confirmed_at, as: :date_time
        field :confirmation_sent_at, as: :date_time
        field :unconfirmed_email, as: :text
        field :failed_attempts, as: :number
        field :unlock_token, as: :text
        field :locked_at, as: :date_time
        field :name, as: :text
        field :email_notification, as: :boolean
        field :sms_notification, as: :boolean
        field :uid, as: :text
        field :provider, as: :text
        field :hashed_password, as: :text
        field :profile_id, as: :number
        field :client_id, as: :number
        field :client_country_id, as: :number
        field :roles, as: :has_and_belongs_to_many
      end
    end
  end
end
