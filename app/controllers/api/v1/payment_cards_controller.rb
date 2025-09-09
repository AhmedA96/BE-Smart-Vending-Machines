# frozen_string_literal: true

module Api
  module V1
    class PaymentCardsController < ApplicationController
      skip_before_action :doorkeeper_authorize!, only: :create
      before_action :find_card, only: %w[destroy toggle_default]

      def index
        @payment_cards = PaymentCard.joins(:payment_customer)
                                    .where(payment_customer: { user_id: current_user.id })
                                    .ransack_filter(params)
      end

      def create
        return render_error('Transaction authorization failed.', :bad_request) unless valid_transaction?

        @payment_card = TapPayments::SaveCardRecord.call(params)
        clean_up_card unless @payment_card.persisted?
        render :show, status: :created
      end

      def toggle_default
        if @payment_card.default?
          @payment_card.update(default: false)
        else
          reset_all_user_cards_default
          @payment_card.update(default: true)
        end

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
        TapPayments::ValidateRequest.new(params, request.headers).call
      end

      def valid_transaction?
        params[:status] == 'VALID' && params.dig('response', 'code') == '001'
      end

      def request_user
        User.find(params[:user_id])
      end

      def reset_all_user_cards_default
        user_cards = PaymentCard.joins(:payment_customer)
                                .where(payment_customer: { user_id: current_user.id })
        user_cards.find_each do |card|
          card.update(default: false)
        end
      end
    end
  end
end
