# frozen_string_literal: true

ROLES = %i[admin].freeze
PAYMENT_METHODS = {
  credit: 'credit',
  apple_pay: 'apple pay',
  google_pay: 'google pay'
}.freeze
CURRENCIES = %w[SAR AED].freeze
CURRENCY_MAPPINGS = {
  'UAE' => { 'ar' => 'د.إ', 'en' => 'AED' },
  'KSA' => { 'ar' => '﷼', 'en' => 'SAR' }
}.freeze
