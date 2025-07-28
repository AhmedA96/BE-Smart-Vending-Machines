# frozen_string_literal: true

json.extract! payment_card, :id, :payment_customer_id, :card_id, :funding,
              :fingerprint, :brand, :scheme, :category, :exp_month,
              :exp_year, :last_four, :first_six, :first_eight,
              :name, :default, :updated_at, :created_at
