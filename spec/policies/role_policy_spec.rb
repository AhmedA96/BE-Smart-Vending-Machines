# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RolePolicy, type: :policy do
  subject { described_class }

  let(:super_admin) { create(:user, :super_admin) }
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  permissions :index?, :show?, :update? do
    context 'when the user is a super admin' do
      it 'grants access' do
        expect(subject).to permit(super_admin)
      end
    end

    context 'when the user is an admin' do
      it 'grants access' do
        expect(subject).to permit(admin)
      end
    end

    context 'when the user is not a super admin or admin' do
      it 'denies access' do
        expect(subject).not_to permit(user)
      end
    end
  end
end
