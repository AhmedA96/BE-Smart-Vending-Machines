# frozen_string_literal: true

# == Schema Information
#
# Table name: machine_translations
#
#  id         :bigint           not null, primary key
#  locale     :string           not null
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  machine_id :bigint           not null
#
# Indexes
#
#  index_machine_translations_on_locale                 (locale)
#  index_machine_translations_on_machine_id_and_locale  (machine_id,locale) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (machine_id => machines.id)
#
class MachineTranslation < ApplicationRecord
  belongs_to :machine

  validates :name, :locale, presence: true
  validates :locale, uniqueness: { scope: :machine_id }
end
