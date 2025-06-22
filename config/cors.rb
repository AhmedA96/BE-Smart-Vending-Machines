# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ['https://vndg.me', 'http://localhost:3000', 'http://localhost:8081']
    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head]
  end
end
