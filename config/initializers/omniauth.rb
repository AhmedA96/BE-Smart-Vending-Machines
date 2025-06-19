# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch('GOOGLE_CLIENT_ID', nil),
           ENV.fetch('GOOGLE_CLIENT_SECRET', nil),
           {
             scope: 'email,profile'
           }

  provider :apple,
           ENV.fetch('APPLE_CLIENT_ID', nil),
           ENV.fetch('APPLE_TEAM_ID', nil),
           {
             key_id: ENV.fetch('APPLE_KEY_ID', nil),
             pem: ENV.fetch('APPLE_PRIVATE_KEY', nil),
             scope: 'email name'
           }
end
