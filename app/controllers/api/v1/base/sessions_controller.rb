# frozen_string_literal: true

module Api
  module V1
    module Base
      class SessionsController < Devise::SessionsController
        include ErrorHandling

        respond_to :json
        skip_before_action :verify_authenticity_token
        skip_before_action :verify_signed_out_user, only: :destroy

        def create
          resource = find_resource
          if resource&.valid_password?(params[:password])
            sign_in(resource)
            head :created
          else
            render_error('Invalid email or password', :unprocessable_entity)
          end
        end

        def destroy
          if current_user.is_a?(resource_class)
            revoke_access_token
            sign_out(current_user)
          end

          head :no_content
        end

        def current_user
          return super unless doorkeeper_token

          user_model = Constantizer.safe_constantize(doorkeeper_token.resource_owner_type)
          @current_user ||= user_model.find(doorkeeper_token.resource_owner_id)
        end

        private

        def find_resource
          resource_class.find_by(email: params[:email])
        end

        def resource_class
          raise NotImplementedError, 'Subclasses must implement this method'
        end

        def revoke_access_token
          token = request.headers['Authorization']&.split&.last
          return unless token

          access_token = Doorkeeper::AccessToken.find_by(token:)
          access_token&.update(revoked_at: Time.zone.now)
        end
      end
    end
  end
end
