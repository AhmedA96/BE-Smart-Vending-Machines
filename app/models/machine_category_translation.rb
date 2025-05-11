# frozen_string_literal: true

# == Schema Information
#
# Table name: machine_category_translations
#
#  id                  :bigint           not null, primary key
#  description         :text
#  locale              :string           not null
#  presentation        :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  machine_category_id :bigint           not null
#
# Indexes
#
#  index_machine_category_translations_on_locale            (locale)
#  index_mc_translations_on_machine_category_id_and_locale  (machine_category_id,locale) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (machine_category_id => machine_categories.id)
#
class MachineCategoryTranslation < ApplicationRecord
  belongs_to :machine_category

  validates :presentation, :locale, presence: true
  validates :locale, uniqueness: { scope: :machine_category_id }
end
