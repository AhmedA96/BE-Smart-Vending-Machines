# frozen_string_literal: true

# == Schema Information
#
# Table name: user_favorites
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :bigint
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_favorites_on_created_at              (created_at)
#  index_user_favorites_on_product_id              (product_id)
#  index_user_favorites_on_user_id                 (user_id)
#  index_user_favorites_on_user_id_and_product_id  (user_id,product_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (user_id => users.id)
#
class UserFavorite < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :user_id, uniqueness: { scope: :product_id }

  scope :recent, -> { order(created_at: :desc) }

  def display_name
    if user && product
      "#{user.name} Likes #{product&.name}"
    else
      "Favorite ##{id}"
    end
  end
end
