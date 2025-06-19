# frozen_string_literal: true

module TapPayments
  class SaveCardRecord < BaseService
    class << self
      def call(params)
        payment_customer_number = params.dig('customer', 'id')
        user_id = params['user_id']
        card = params['card']

        payment_customer = PaymentCustomer.find_or_create_by!(
          payment_customer_number:,
          user_id:
        )

        PaymentCard.create!(
          payment_customer_id: payment_customer.id,
          card_id: card['id'],
          funding: card['funding'],
          fingerprint: card['fingerprint'],
          brand: card['brand'],
          scheme: card['scheme'],
          category: card['category'],
          exp_month: card['exp_month'] || card['expiry']['month'],
          exp_year: card['exp_year'] || card['expiry']['year'],
          last_four: card['last_four'],
          first_six: card['first_six'],
          first_eight: card['first_eight'],
          name: card['name'],
          payment_agreement_id: params.dig('payment_agreement', 'id')
        )
      end
    end
  end
end
