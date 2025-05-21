# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_application, class: 'Doorkeeper::Application' do
    name { 'Test Application' }
    uid { SecureRandom.hex(8) }
    secret { SecureRandom.hex(16) }
    redirect_uri { '' }
    scopes { '' }
    confidential { true }
  end
end
