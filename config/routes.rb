# frozen_string_literal: true

Rails.application.routes.draw do
  mount Avo::Engine, at: Avo.configuration.root_path
  devise_for :users
  use_doorkeeper

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      namespace :users do
        devise_for :users, path: '', path_names: {
                                       sign_in: 'login',
                                       sign_out: 'logout',
                                       registration: 'signup'
                                     },
                           controllers: {
                             sessions: 'api/v1/users/sessions',
                             registrations: 'api/v1/users/registrations'
                           }
      end
    end
  end
end
