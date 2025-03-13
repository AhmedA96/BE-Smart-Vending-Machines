# frozen_string_literal: true

module Api
  module V1
    module Base
      class RegistrationsController < Devise::RegistrationsController
        include ErrorHandling

        respond_to :json
        skip_before_action :verify_authenticity_token
      end
    end
  end
end
