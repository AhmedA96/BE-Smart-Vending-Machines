# frozen_string_literal: true

ROLES = %i[admin].freeze
CURRENCIES = %w[SAR AED].freeze
CURRENCY_MAPPINGS = {
  'UAE' => { 'ar' => 'د.إ', 'en' => 'AED' },
  'KSA' => { 'ar' => '﷼', 'en' => 'SAR' }
}.freeze
PAYMENT_OPERATION_TYPES = {
  order_payment: 'Order Payment',
  wallet_refill: 'Wallet Refill'
}.freeze
