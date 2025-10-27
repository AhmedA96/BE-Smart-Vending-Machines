# frozen_string_literal: true

module TapPayments
  class SaveCardRecord < BaseService
    class << self
      def call(params)
        customer_id = params.dig('customer', 'id')
        user_id = params.dig('metadata', 'user_id')
        card = params['card'] || params['source']

        payment_customer = PaymentCustomer.find_or_create_by!(
          payment_customer_number: customer_id,
          user_id: user_id
        )

        PaymentCard.create!(
          payment_customer_id: payment_customer.id,
          card_id: card['id'],
          funding: card['payment_type'] || card['funding'] || 'CREDIT',
          brand: card['brand'],
          scheme: card['scheme'],
          category: card['category'],
          exp_month: card.dig('expiry', 'month'),
          exp_year: card.dig('expiry', 'year'),
          last_four: card['last_four'] || card['last4'],
          first_six: card['first_six'],
          first_eight: card['first_eight'],
          name: card['name'] || params.dig('customer', 'first_name'),
          payment_agreement_id: params.dig('payment_agreement', 'id')
        )
      end
    end
  end
end
