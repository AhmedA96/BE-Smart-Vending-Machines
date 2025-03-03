source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.1'

# Core
gem 'rails', '~> 8.0'
gem 'pg', '~> 1.5'
gem 'puma', '>= 6.4.2'

# Authentication & Authorization
gem 'devise', '~> 4.9'
gem 'doorkeeper', '~> 5.6'
gem 'rolify'
gem 'pundit'

# Data Management
gem 'acts_as_paranoid', github: 'ActsAsParanoid/acts_as_paranoid', branch: 'master'
gem 'paper_trail'
gem 'ransack'
gem 'pg_search'

# API & Communication
gem 'jbuilder'
gem 'rack-cors', '<= 2.0.2'
gem 'phonelib'

# Background Jobs
gem 'sidekiq', '~> 7.2'
gem 'redis'

# File Storage
gem 'aws-sdk-s3'
gem 'image_processing', '~> 1.2'

# Utilities
gem 'dotenv-rails'
gem 'rails-i18n'
gem 'bootsnap', require: false

# Password Security
gem 'pbkdf2'
gem 'pbkdf2-ruby'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'debug'
  gem 'brakeman'
  gem 'bundle-audit'
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