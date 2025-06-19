# frozen_string_literal: true

Rails.application.routes.draw do
  get '/', to: redirect('/admin')
  authenticate :user, ->(u) { u.admin? } do
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
        post 'auth/google', to: 'omniauth_callbacks#google'
        post 'auth/apple', to: 'omniauth_callbacks#apple'
      end

      resources :machines do
        collection do
          get :nearby
        end
      end

      resources :machine_categories
      resources :categories

      resources :products do
        collection do
          get 'machine_products'
        end
      end

      resources :orders
      resources :variants, only: %i[index show]

      post 'contact-us', to: 'contact_us_requests#create'

      resources :payment_methods, only: %i[index show]

      post 'mobile_verifications/send_code', to: 'mobile_verifications#send_verification_code'
      post 'mobile_verifications/verify_code', to: 'mobile_verifications#verify_code'
    end
  end

  # Health check endpoint for deployment monitoring
  get '/up', to: 'rails/health#show', as: :rails_health_check
end
