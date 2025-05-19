# frozen_string_literal: true

module Api
  module V1
    class ApplicationController < ActionController::Base
      include Pundit::Authorization
      include ErrorHandling
      include Localization
      include Pagy::Backend
      include Paginable

      skip_before_action :verify_authenticity_token
      before_action :doorkeeper_authorize!

      def current_user
        return unless doorkeeper_token
        return nil if doorkeeper_token.resource_owner_id.nil?

        @current_user = User.find(doorkeeper_token.resource_owner_id)
      end

      def check_authorization
        authorize model_class, "#{action_name}?"
      end

      def check_policy_scope
        @policy_scope = policy_scope(model_class)
      end
    end
  end
end
