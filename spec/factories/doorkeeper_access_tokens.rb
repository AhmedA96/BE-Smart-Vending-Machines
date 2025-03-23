# frozen_string_literal: true

FactoryBot.define do
  factory :doorkeeper_access_token, class: 'Doorkeeper::AccessToken' do
    association :resource_owner, factory: :user
    application { nil } # For password grant type, no application is needed
    scopes { '' }
    expires_in { 2.hours }
    created_at { Time.current }
    token { SecureRandom.hex(32) }
    refresh_token { SecureRandom.hex(32) }
  end
end
