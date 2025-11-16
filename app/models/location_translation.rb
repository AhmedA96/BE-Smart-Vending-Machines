# frozen_string_literal: true

# == Schema Information
#
# Table name: location_translations
#
#  id           :bigint           not null, primary key
#  locale       :string           not null
#  presentation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  location_id  :bigint           not null
#
# Indexes
#
#  index_location_translations_on_locale                  (locale)
#  index_location_translations_on_location_id_and_locale  (location_id,locale) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#
class LocationTranslation < ApplicationRecord
  belongs_to :location

  validates :presentation, :locale, presence: true
  validates :locale, uniqueness: { scope: :location_id }
end
