# frozen_string_literal: true

module Api
  module V1
    class ContactUsRequestsController < ApplicationController
      skip_before_action :doorkeeper_authorize!

      def create
        @contact = ContactUsRequest.new(contact_params)

        if @contact.save
          render json: @contact, status: :created
        else
          render json: {
            errors: @contact.errors.messages
          }, status: :unprocessable_content
        end
      end

      private

      def contact_params
        params.expect(contact: %i[full_name email company_name phone_number])
      end
    end
  end
end
