# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:other_user) { create(:user) }

  subject { described_class }

  permissions '.scope' do
    let(:scope) { User.all }

    context 'when user is admin' do
      let(:user) { admin }
      it 'shows all users' do
        expect(Pundit.policy_scope!(user, User)).to eq scope
      end
    end

    context 'when user is regular user' do
      let(:user) { regular_user }
      it 'shows only themselves' do
        expect(Pundit.policy_scope!(user, User)).to eq scope.where(id: user.id)
      end
    end

    context 'when user is not authenticated' do
      let(:user) { nil }
      it 'shows no users' do
        expect(Pundit.policy_scope!(user, User)).to eq scope.none
      end
    end
  end

  permissions :show? do
    it 'denies access if not admin' do
      expect(subject).not_to permit(regular_user, other_user)
    end

    it 'allows access if  admin' do
      expect(subject).to permit(admin, other_user)
    end
  end

  permissions :create?, :update?, :new?, :edit? do
    it 'denies access if not admin' do
      expect(subject).not_to permit(regular_user, other_user)
    end
    it 'allows access if admin' do
      expect(subject).to permit(admin, other_user)
    end
  end

  permissions :destroy? do
    it 'denies access if not admin' do
      expect(subject).not_to permit(regular_user, other_user)
    end

    it 'allows access if  admin' do
      expect(subject).to permit(admin, other_user)
    end
  end
end
