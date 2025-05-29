# frozen_string_literal: true

# == Schema Information
#
# Table name: country_translations
#
#  id           :bigint           not null, primary key
#  currency     :string
#  locale       :string           not null
#  presentation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  country_id   :bigint           not null
#
# Indexes
#
#  index_country_translations_on_country_id_and_locale  (country_id,locale) UNIQUE
#  index_country_translations_on_locale                 (locale)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#
class CountryTranslation < ApplicationRecord
  belongs_to :country

  validates :presentation, :currency, :locale, presence: true
  validates :locale, uniqueness: { scope: :country_id }

  before_validation :set_currency

  private

  def set_currency
    return unless locale == 'ar'

    self.currency = CURRENCY_MAPPINGS.dig(country.name, locale)
  end
end
