# frozen_string_literal: true

module Wallets
  class CreateCreditCharge
    def self.call(wallet_refill, user)
      payment = wallet_refill

      card = find_card(user, payment)
      validate_card_presence!(card)

      token_id = create_card_token(card, user, payment)

      charge_response = create_card_charge(payment, token_id, user)

      process_charge_response(payment, charge_response)
    end

    def self.credit_payment?(payment)
      payment.payment_method.name == 'credit'
    end

    def self.find_card(user, payment)
      user.payment_cards.find_by(id: payment.card_id)
    end

    def self.validate_card_presence!(card)
      raise StandardError, I18n.t('payment.card_not_found') unless card
    end

    def self.create_card_token(card, user, payment)
      token_response = TapPayments::CreateCardToken.call(
        card.card_id,
        user.payment_customer.payment_customer_number
      )
      validate_token_response!(token_response, payment, user)
      JSON.parse(token_response.body)['id']
    end

    def self.validate_token_response!(token_response, _payment, _user)
      return if successful_response?(token_response)

      raise StandardError, I18n.t('payment.failed_to_create_token_for_card')
    end

    def self.create_card_charge(payment, token_id, user)
      TapPayments::CreateCardCharge.call(
        PAYMENT_OPERATION_TYPES[:wallet_refill],
        payment,
        token_id,
        payment.card_id,
        user
      )
    end

    def self.successful_response?(response)
      response.code == 200
    end

    def self.process_charge_response(payment, response)
      raise StandardError, I18n.t('errors.card.failed_to_create_charge') unless successful_response?(response)

      status = JSON.parse(response.body)['status']
      code = JSON.parse(response.body)['response']['code']
      unless status == 'CAPTURED' && code == '000'
        payment.failed!
        payment.update!(message: JSON.parse(response.body)['response']['message'])
        raise StandardError, I18n.t('errors.card.failed_to_capture_charge')
      end

      true
    end
  end
end
