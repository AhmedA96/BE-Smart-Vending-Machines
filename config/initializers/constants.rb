# frozen_string_literal: true

ROLES = %i[admin].freeze
CURRENCIES = %w[SAR AED].freeze
CURRENCY_MAPPINGS = {
  'UAE' => { 'ar' => 'د.إ', 'en' => 'AED' },
  'KSA' => { 'ar' => '﷼', 'en' => 'SAR' }
}.freeze
