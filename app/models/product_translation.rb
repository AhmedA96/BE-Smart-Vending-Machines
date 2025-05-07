# frozen_string_literal: true

# == Schema Information
#
# Table name: product_translations
#
#  id           :bigint           not null, primary key
#  description  :text
#  locale       :string           not null
#  presentation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  product_id   :bigint           not null
#
# Indexes
#
#  index_product_translations_on_locale                 (locale)
#  index_product_translations_on_product_id_and_locale  (product_id,locale) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#
class ProductTranslation < ApplicationRecord
  belongs_to :product, optional: false

  validates :description, :locale, presence: true
  validates :locale, uniqueness: { scope: :product_id }
end
