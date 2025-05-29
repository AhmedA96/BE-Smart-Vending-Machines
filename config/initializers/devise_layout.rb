# frozen_string_literal: true

Rails.application.config.to_prepare do
  Devise::SessionsController.layout 'devise'
  Devise::RegistrationsController.layout 'devise'
  Devise::ConfirmationsController.layout 'devise'
  Devise::UnlocksController.layout 'devise'
  Devise::PasswordsController.layout 'devise'
  Devise::Mailer.layout 'mailer'
end
