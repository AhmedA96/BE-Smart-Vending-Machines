# frozen_string_literal: true

module Api
  module V1
    module Base
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json
        skip_before_action :verify_authenticity_token

        protected

        def render_error(errors, status)
          @errors = errors.is_a?(String) ? [errors] : errors
          render 'api/v1/shared/error', formats: :json, status:
        end
      end
    end
  end
end
