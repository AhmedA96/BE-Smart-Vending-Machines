# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersRolePolicy, type: :policy do
  subject { described_class }

  permissions :index?, :show?, :update?, :create?, :destroy? do
    context 'when the user is admin' do
      it 'grants access' do
        expect(subject).to permit(admin)
      end
    end

    context 'when the user is not admin' do
      it 'denies access' do
        expect(subject).not_to permit(user)
      end
    end
  end
end
