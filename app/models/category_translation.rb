# frozen_string_literal: true

# == Schema Information
#
# Table name: category_translations
#
#  id           :bigint           not null, primary key
#  description  :text
#  locale       :string           not null
#  presentation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  category_id  :bigint           not null
#
# Indexes
#
#  index_category_translations_on_category_id_and_locale  (category_id,locale) UNIQUE
#  index_category_translations_on_locale                  (locale)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#
class CategoryTranslation < ApplicationRecord
  belongs_to :category

  validates :presentation, :locale, presence: true
  validates :locale, uniqueness: { scope: :category_id }
end
