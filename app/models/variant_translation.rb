# frozen_string_literal: true

# == Schema Information
#
# Table name: variant_translations
#
#  id           :bigint           not null, primary key
#  locale       :string           not null
#  presentation :string
#  size         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  variant_id   :bigint           not null
#
# Indexes
#
#  index_variant_translations_on_locale                 (locale)
#  index_variant_translations_on_variant_id             (variant_id)
#  index_variant_translations_on_variant_id_and_locale  (variant_id,locale) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (variant_id => variants.id)
#
class VariantTranslation < ApplicationRecord
  belongs_to :variant

  validates :presentation, :locale, presence: true
  validates :locale, uniqueness: { scope: :variant_id }
end
