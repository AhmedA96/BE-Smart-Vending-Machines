# frozen_string_literal: true

module Api
  module V1
    class ContactUsRequestsController < ApplicationController
      def create
        @contact = ContactUsRequest.create!(contact_params)
      end

      private

      def contact_params
        params.expect(contact: %i[full_name email company_name phone_number])
      end
    end
  end
end
