# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.2'

# Core
gem 'pg', '~> 1.5'
gem 'puma', '>= 6.4.2'
gem 'rails', '~> 8.0'

# Authentication & Authorization
gem 'devise', '~> 4.9'
gem 'doorkeeper', '~> 5.6'
gem 'pundit'
gem 'rolify'

# Data Management
gem 'acts_as_paranoid', github: 'ActsAsParanoid/acts_as_paranoid', branch: 'master'
gem 'paper_trail'
gem 'pg_search'
gem 'ransack'

# API & Communication
gem 'jbuilder'
gem 'phonelib'
gem 'rack-cors', '<= 2.0.2'

# Background Jobs
gem 'redis'
gem 'sidekiq', '~> 7.2'

# File Storage
gem 'aws-sdk-s3'
gem 'image_processing', '~> 1.2'

# Utilities
gem 'bootsnap', require: false
gem 'dotenv-rails'
gem 'rails-i18n'

# Password Security
gem 'pbkdf2'
gem 'pbkdf2-ruby'

group :development, :test do
  gem 'brakeman'
  gem 'bundle-audit'
  gem 'debug'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
end

group :development do
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'letter_opener_web'
end

group :test do
  gem 'database_cleaner-active_record'
  gem 'shoulda-matchers'
  gem 'simplecov'
end
