# frozen_string_literal: true

Rails.application.routes.draw do
  get '/', to: redirect('/admin')
  authenticate :user, ->(u) { u.super_admin? || u.admin? } do
    mount Rswag::Ui::Engine => '/api-docs'
    mount Rswag::Api::Engine => '/api-docs'
  end
  authenticate :user do
    mount Avo::Engine, at: Avo.configuration.root_path
  end
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

      resources :vending_machines, only: [] do
        collection do
          get :nearby
        end
      end
    end
  end
end
