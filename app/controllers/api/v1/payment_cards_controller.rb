# frozen_string_literal: true

module Api
  module V1
    class PaymentCardsController < ApplicationController
      skip_before_action :doorkeeper_authorize!, only: :create
      before_action :find_card, only: %i[destroy toggle_default]

      def index
        @payment_cards = current_user.payment_cards.ransack_filter(params)
      end

      def create
        return render_error('Transaction authorization failed.', :bad_request) unless valid_transaction?

        @payment_card = TapPayments::SaveCardRecord.call(params)
        clean_up_card unless @payment_card.persisted?

        assign_default_if_first_card(@payment_card)

        render :show, status: :created
      end

      def toggle_default
        if @payment_card.default?
          @payment_card.update(default: false)
        else
          current_user.payment_cards.find_each { |card| card.update(default: false) }
          @payment_card.update(default: true)
        end

        render :show, status: :ok
      end

      def destroy
        was_default = @payment_card.default?
        @payment_card.destroy!

        assign_next_default_if_needed if was_default

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
        @payment_card = current_user.payment_cards.find(params[:id])
      end

      def valid_transaction?
        params[:status] == 'VALID' && params.dig('response', 'code') == '001'
      end

      def assign_default_if_first_card(card)
        # make the first added card default
        return unless current_user.payment_cards.one?

        card.update(default: true)
      end

      def assign_next_default_if_needed
        next_card = current_user.payment_cards.order(:created_at).first
        next_card&.update(default: true)
      end
    end
  end
end
