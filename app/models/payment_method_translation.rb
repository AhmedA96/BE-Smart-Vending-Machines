# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_method_translations
#
#  id                :bigint           not null, primary key
#  description       :text
#  locale            :string           not null
#  presentation      :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  payment_method_id :bigint           not null
#
# Indexes
#
#  index_payment_method_translations_on_locale            (locale)
#  index_pm_translations_on_payment_method_id_and_locale  (payment_method_id,locale) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (payment_method_id => payment_methods.id)
#
class PaymentMethodTranslation < ApplicationRecord
  belongs_to :payment_method

  validates  :locale, presence: true
end
