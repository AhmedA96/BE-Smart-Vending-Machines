# frozen_string_literal: true

shared_context 'users#roles' do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
end
