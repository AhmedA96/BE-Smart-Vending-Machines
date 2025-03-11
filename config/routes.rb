# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  use_doorkeeper

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      devise_for :users, controllers: {
        registrations: 'api/v1/users/registrations'
      }
    end
  end
end
