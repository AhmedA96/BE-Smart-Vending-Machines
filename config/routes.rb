# frozen_string_literal: true

require 'solid_queue_monitor'

Rails.application.routes.draw do
  get '/', to: redirect('/admin')

  # Admin-only API docs
  authenticate :user, ->(u) { u.admin? } do
    mount Rswag::Ui::Engine => '/api-docs'
    mount Rswag::Api::Engine => '/api-docs'
    mount SolidQueueMonitor::Engine => '/solid_queue'
    mount SolidQueueDashboard::Engine, at: '/solid-queue'
  end

  # Authenticated Avo panel
  authenticate :user do
    mount Avo::Engine, at: Avo.configuration.root_path
  end
  get '/admin', to: redirect('/users/sign_in')

  devise_for :users,
             skip: %i[registrations],
             path: 'users'

  use_doorkeeper

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # -----------------------------
      # Devise API routes
      # -----------------------------
      devise_scope :user do
        post 'users/login', to: 'users/sessions#create'
        delete 'users/logout', to: 'users/sessions#destroy'
        post 'users/signup', to: 'users/registrations#create'
      end

      # -----------------------------
      # Custom user/password routes
      # -----------------------------
      namespace :users do
        post 'passwords/change', to: 'passwords#change_password'
        post 'passwords/forgot', to: 'passwords#forgot_password'
        post 'passwords/reset', to: 'passwords#reset_password'
        post 'auth/google', to: 'omniauth_callbacks#google'
        post 'auth/apple', to: 'omniauth_callbacks#apple'
      end

      # -----------------------------
      # User routes
      # -----------------------------
      resources :users, only: [] do
        collection do
          get :profile
          patch :update_profile
          delete :destroy
          post 'favorites/:product_id', to: 'user_favorites#create'
          delete 'favorites/:product_id', to: 'user_favorites#destroy'
          get :most_ordered
          get :favorites
        end
      end

      # -----------------------------
      # Machines & categories
      # -----------------------------
      resources :machines, only: %i[index show] do
        resources :categories, only: %i[index show]

        collection do
          get :nearby
        end
      end

      resources :machine_categories, only: %i[index show]

      resources :categories, only: %i[index show] do
        collection do
          get :with_brands
        end
      end

      # -----------------------------
      # Products, brands, variants
      # -----------------------------
      resources :products, only: %i[index show] do
        collection do
          get :machine_products
        end
      end

      resources :brands, only: %i[index show]
      resources :variants, only: %i[index show]

      # -----------------------------
      # Cart & orders
      # -----------------------------
      resources :carts, controller: :cart, except: [:destroy] do
        resources :line_items, except: %i[index show]
        member do
          put :update_owner
        end
      end

      resources :orders, only: %i[index show] do
        member do
          post :reorder
          put :checkout
          get :status
        end
      end

      # -----------------------------
      # Payments
      # -----------------------------
      resources :payment_methods, only: %i[index show]
      resources :payments, only: %i[index show create]

      resources :payment_cards, only: %i[index create destroy] do
        member do
          post :toggle_default
        end
      end

      # -----------------------------
      # Mobile verification
      # -----------------------------
      post 'mobile_verifications/send_code', to: 'mobile_verifications#send_verification_code'
      post 'mobile_verifications/verify_code', to: 'mobile_verifications#verify_code'

      # -----------------------------
      # Locations
      # -----------------------------
      resources :locations do
        collection do
          get :nearby
        end
      end

      # -----------------------------
      # Items
      # -----------------------------
      resources :items, only: [] do
        collection do
          get :popular
          get :trending
        end
      end

      # -----------------------------
      # Wallet
      # -----------------------------
      get 'my_wallet', to: 'wallets#my_wallet'

      resources :wallet_refills, only: %i[create] do
        collection do
          get :valid_amounts
        end
      end

      resources :wallet_transactions, only: %i[index show]

      # -----------------------------
      # Webhooks & contact
      # -----------------------------
      resources :tap_webhook, only: %i[create]
      post 'contact-us', to: 'contact_us_requests#create'

      # -----------------------------
      # Notifications & devices
      # -----------------------------
      resources :notifications, only: %i[index destroy] do
        member do
          put :mark_as_read
        end
        collection do
          put :mark_all_as_read
        end
      end

      resources :devices, only: %i[create destroy]
    end
  end

  # Health check
  get '/up', to: 'rails/health#show', as: :rails_health_check
end
