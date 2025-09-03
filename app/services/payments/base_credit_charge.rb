# frozen_string_literal: true

module Payments
  class BaseCreditCharge
    def self.call(source, user, source_type)
      payment = find_payment(source)

      card = find_card(user, payment)
      validate_card_presence!(card)

      token_id = create_card_token(card, user, payment)
      charge_response = create_card_charge(payment, token_id, user, source_type)
      process_charge_response(payment, charge_response, source)
      TapPayments::SaveChargeRecord.call(charge_response, user.payment_customer.id, payment.id)
    end

    def self.find_payment(source)
      source.payments.first
    end

    def self.find_card(user, payment)
      user.payment_customer.payment_cards.find_by(id: payment.card_id)
    end

    def self.validate_card_presence!(card)
      raise StandardError, I18n.t('errors.card.card_not_found') unless card
    end

    def self.create_card_token(card, user, payment)
      token_response = TapPayments::CreateCardToken.call(
        card.card_id,
        user.payment_customer.payment_customer_number
      )
      validate_token_response!(token_response, payment, user)
      token_id = JSON.parse(token_response.body)['id']
      payment.update(token_id: token_id)
      token_id
    end

    def self.validate_token_response!(token_response, _payment, _user)
      return if successful_response?(token_response)

      raise StandardError, I18n.t('errors.card.failed_to_create_token_for_card')
    end

    def self.create_card_charge(payment, token_id, user, source_type)
      TapPayments::CreateCardCharge.call(
        source_type,
        payment,
        token_id,
        payment.card_id,
        user
      )
    end

    def self.successful_response?(response)
      response.code == 200
    end

    def self.process_charge_response(payment, response, source)
      raise StandardError, I18n.t('errors.card.failed_to_create_charge') unless successful_response?(response)

      response_body = JSON.parse(response.body)

      if response_body.key?('errors')
        payment.failed!
        payment.update!(message: response_body['errors'].first['description'])
        raise StandardError, response_body['errors'].first['description']
      end

      status = response_body['status']
      code = response_body['response']['code']

      unless status == 'CAPTURED' && code == '000'
        payment.failed!
        payment.update!(message: response_body['response']['message'])
        raise StandardError, I18n.t('errors.card.failed_to_capture_charge')
      end

      complete_transaction(payment, source)

      true
    end

    def self.complete_transaction(payment, source)
      payment.complete!
      source.mark_paid! if source.respond_to?(:mark_paid!)
    end
  end
end
