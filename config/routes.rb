# frozen_string_literal: true

require 'solid_queue_monitor'

Rails.application.routes.draw do
  get '/', to: redirect('/admin')
  authenticate :user, ->(u) { u.admin? } do
    mount Rswag::Ui::Engine => '/api-docs'
    mount Rswag::Api::Engine => '/api-docs'
    mount SolidQueueMonitor::Engine => '/solid_queue'
    mount SolidQueueDashboard::Engine, at: '/solid-queue'
  end
  authenticate :user do
    mount Avo::Engine, at: Avo.configuration.root_path
  end
  devise_for :users
  use_doorkeeper

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      namespace :users do
        post 'passwords/change', to: 'passwords#change_password'
        post 'passwords/forgot', to: 'passwords#forgot_password'
        post 'passwords/reset', to: 'passwords#reset_password'
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

      resources :users do
        collection do
          get :profile
          patch :update_profile
          delete :destroy
          post 'favorites/:product_id', to: 'user_favorites#create'
          delete 'favorites/:product_id', to: 'user_favorites#destroy'
          get :most_ordered
          get :favorites
        end
        member do
          resources :payment_cards, only: %i[create]
        end
      end
      resources :machines, only: %i[index show] do
        collection do
          get :nearby
        end
      end

      resources :machine_categories
      resources :categories do
        collection do
          get :with_brands
        end
      end

      resources :products do
        collection do
          get :machine_products
        end
      end
      resources :brands, only: %i[index show]

      resources :carts, controller: :cart, except: [:destroy] do
        resources :line_items, except: %i[index show]
        member do
          put :update_owner
        end
      end

      resources :orders, only: %i[index show] do
        member do
          post :reorder
          post :create_pickup_code
          put :checkout
        end
      end

      resources :variants, only: %i[index show]

      post 'contact-us', to: 'contact_us_requests#create'

      resources :payment_methods, only: %i[index show]
      resources :payments, only: %i[index show create]
      resources :payment_cards, only: %i[index create destroy] do
        member do
          post :toggle_default
        end
      end

      post 'mobile_verifications/send_code', to: 'mobile_verifications#send_verification_code'
      post 'mobile_verifications/verify_code', to: 'mobile_verifications#verify_code'

      resources :locations do
        collection do
          get :nearby
        end
      end

      resources :wallets, only: %i[index]

      resources :items, only: [] do
        collection do
          get :popular
          get :trending
        end
      end

      resources :tap_webhook, only: [:create]
      resources :tap_redirect, only: :index
    end
  end

  # Health check endpoint for deployment monitoring
  get '/up', to: 'rails/health#show', as: :rails_health_check
end
