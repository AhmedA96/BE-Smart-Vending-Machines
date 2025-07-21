# frozen_string_literal: true

# == Schema Information
#
# Table name: user_favorites
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#  variant_id :bigint           not null
#
# Indexes
#
#  index_user_favorites_on_created_at              (created_at)
#  index_user_favorites_on_user_id                 (user_id)
#  index_user_favorites_on_user_id_and_variant_id  (user_id,variant_id) UNIQUE
#  index_user_favorites_on_variant_id              (variant_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (variant_id => variants.id)
#
class UserFavorite < ApplicationRecord
  belongs_to :user
  belongs_to :variant

  validates :user_id, uniqueness: { scope: :variant_id }

  scope :recent, -> { order(created_at: :desc) }
end
