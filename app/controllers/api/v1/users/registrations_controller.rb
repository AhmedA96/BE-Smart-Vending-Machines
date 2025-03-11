# frozen_string_literal: true

module Api
  module V1
    module Users
      class RegistrationsController < Base::RegistrationsController
        rate_limit to: 10, within: 1.hour, with: lambda {
          render_error(I18n.t('errors.too_many_requests'), :too_many_requests)
        }, only: :create

        def create
          build_resource(user_params)
          resource.client_id = user_params[:client_id]

          resource.save ? render('create', status: :created) : render_error(resource.errors, :unprocessable_entity)
        end

        private

        def user_params
          params.permit(:name, :email, :password, :mobile_number, :client_id, :date_of_birth, :gender,
                        :sms_notification, :email_notification, :client_country_id, :referred_code)
        end
      end
    end
  end
end
