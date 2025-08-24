# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserFavorite, type: :model do
  let(:user) { users(:user_one) }
  let(:product) { products(:coke_classic) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:product) }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      fav = UserFavorite.new(user: user, product: product)
      expect(fav).to be_valid
    end

    it 'is invalid without a user' do
      fav = UserFavorite.new(product: product)
      expect(fav).not_to be_valid
    end

    it 'is invalid without a product' do
      fav = UserFavorite.new(user: user)
      expect(fav).not_to be_valid
    end

    it 'does not allow duplicate favorites for the same user/product' do
      UserFavorite.create!(user: user, product: product)
      duplicate = UserFavorite.new(user: user, product: product)
      expect(duplicate).not_to be_valid
    end
  end

  describe 'scopes' do
    it 'orders by most recent first' do
      UserFavorite.create!(user: user, product: products(:kit_kat), created_at: 1.day.ago)
      new_fav = UserFavorite.create!(user: user, product: products(:pepsi_cola), created_at: Time.current)

      expect(UserFavorite.recent.first).to eq(new_fav)
    end
  end

  describe '#display_name' do
    it 'returns user and product name when both are present' do
      fav = UserFavorite.new(user: user, product: product)
      expect(fav.display_name).to eq("#{user.name} Likes #{product.name}")
    end

    it "falls back to 'Favorite #id' when missing associations" do
      fav = UserFavorite.new(id: 123)
      expect(fav.display_name).to eq('Favorite #123')
    end
  end
end
