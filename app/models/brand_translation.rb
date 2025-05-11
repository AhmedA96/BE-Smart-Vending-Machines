# frozen_string_literal: true

# == Schema Information
#
# Table name: brand_translations
#
#  id           :bigint           not null, primary key
#  description  :text
#  locale       :string           not null
#  presentation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  brand_id     :bigint           not null
#
# Indexes
#
#  index_brand_translations_on_brand_id_and_locale  (brand_id,locale) UNIQUE
#  index_brand_translations_on_locale               (locale)
#
# Foreign Keys
#
#  fk_rails_...  (brand_id => brands.id)
#
class BrandTranslation < ApplicationRecord
  belongs_to :brand, optional: false

  validates :presentation, :locale, presence: true
  validates :locale, uniqueness: { scope: :brand_id }
end
