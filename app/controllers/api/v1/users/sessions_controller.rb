# frozen_string_literal: true

module Api
  module V1
    module Users
      class SessionsController < Base::SessionsController
        skip_before_action :doorkeeper_authorize!

        rate_limit to: 5, within: 1.minute, with: lambda {
          render_error(I18n.t('errors.too_many_requests'), :too_many_requests)
        }, only: :create

        private

        def resource_class
          User
        end
      end
    end
  end
end
