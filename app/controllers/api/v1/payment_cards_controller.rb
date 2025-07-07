# frozen_string_literal: true

module Api
  module V1
    class PaymentCardsController < ApplicationController
      rescue_from StandardError, with: :render_invalid

      skip_before_action :doorkeeper_authorize!, only: :create

      before_action :find_card, only: %w[destroy mark_as_default undo_default]

      def index
        @payment_cards = PaymentCard.joins(:payment_customer)
                                    .where(payment_customer: { user_id: current_user.id })
                                    .ransack_filter(params)
      end

      def create
        return render_error('Transaction authorization failed.', :bad_request) unless valid_transaction?

        # unless valid_request?
        #   return render_error('Invalid Request', :bad_request)
        # end

        @payment_card = TapPayments::SaveCardRecord.call(params)
        clean_up_card unless @payment_card.persisted?
        render :show, status: :created
      end

      def mark_as_default
        toggle_user_cards
        @payment_card.update(default: true)

        render :show, status: :ok
      end

      def undo_default
        @payment_card.update(default: false)

        render :show, status: :ok
      end

      def destroy
        @payment_card.destroy!
        render json: { message: 'Payment card deleted successfully' }, status: :ok
      end

      private

      def clean_up_card
        card_id = params.dig('card', 'id')
        customer_id = params.dig('customer', 'id')

        return unless card_id && customer_id

        DeleteCardJob.perform_later(card_id, customer_id)
      end

      def find_card
        @payment_card = PaymentCard.find(params[:id])
      end

      def valid_request?
        client_id = params.dig(:metadata, :client_id) || request_user.client_id
        TapPayments::ValidateRequest.new(params, request.headers, client_id).call
      end

      def valid_transaction?
        params[:status] == 'VALID' && params.dig('response', 'code') == '001'
      end

      def request_user
        User.find(params[:user_id])
      end

      def toggle_user_cards
        user_cards = PaymentCard.joins(:payment_customer)
                                .where(payment_customer: { user_id: current_user.id })

        user_cards.find_each do |user_card|
          user_card.update(default: false)
        end
      end
    end
  end
end
