# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.2'

# Core
gem 'bootsnap', require: false
gem 'rails', '~> 8.0'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Database
gem 'activerecord-postgis-adapter', github: "AhmedAliIbrahim/activerecord-postgis-adapter", branch: "rails-8"
gem 'pg', '~> 1.5'
gem "pghero"
gem 'pg_search'
gem 'ransack'
gem 'scenic'

# Authentication & Authorization
gem 'devise', '~> 4.9'
gem 'devise-bootstrap5', '~> 0.1.3'
gem "doorkeeper", "~> 5.6"
gem 'googleauth'
gem 'omniauth-google-oauth2'
gem 'pbkdf2'
gem 'pbkdf2-ruby'
gem "pundit"
gem 'rolify'

# API & Serialization
gem 'activemodel-serializers-xml'
gem 'jbuilder'
gem 'rack-cors', '<= 2.0.2'

# File Storage & Processing
gem 'activestorage'
gem 'aws-sdk-s3'
gem 'down'
gem "image_processing", "~> 1.2"
gem 'mini_magick'

# Background Processing
gem 'sidekiq', '~> 8.0'
gem 'sidekiq-cron', '~> 2.2'
gem 'sidekiq-limit_fetch', '~> 4.4.1'

# Caching & Performance
gem 'kredis'
gem 'puma', '>= 6.4.2'
gem 'rack', '>= 3.1.10'

# Frontend & Assets
gem 'bootstrap', '~> 5.3.1'
gem 'importmap-rails'
gem "sassc-rails"
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'view_component', '>= 3.17'

# Data Processing & Import
gem 'base64'
gem 'creek'
gem 'roo'
gem 'smarter_csv'

# Monitoring & Logging
gem 'newrelic_rpm', '~> 9.15'
gem 'paper_trail'
gem 'status-page'

# Geolocation & Maps
gem 'geocoder'
gem 'mapkick'
gem "mapkick-rb"

# Utilities
gem 'aasm', '~> 5.0'
gem "acts_as_list"
gem 'acts_as_paranoid', github: 'ActsAsParanoid/acts_as_paranoid', branch: 'master'
gem "auto_increment"
gem "chartkick"
gem "groupdate"
gem 'httparty'
gem 'kaminari'
gem "kmeans-clusterer"
gem 'money'
gem 'ostruct'
gem 'phonelib'
gem 'timecop'
gem 'tod'

# Internationalization
gem 'mobility', '~> 1.3.0.rc3'
gem 'mobility-ransack', '~> 1.2.2'
gem 'rails-i18n'

# Admin
gem 'avo', '>= 3.11'
# gem "avo-advanced", ">= 3.11", source: "https://packager.dev/avo-hq/"

# Third Party Services
gem 'cequens', github: 'AhmedAliIbrahim/cequens', branch: 'main'
gem 'fcm', '~> 2.0.0'
gem 'google-apis-drive_v3', '~> 0.54'

# Development Tools
group :development do
  gem "actual_db_schema"
  gem 'annotaterb'
  gem 'better_errors'
  gem "binding_of_caller"
  gem 'memory_profiler'
  gem "pg_query"
  gem 'rack-mini-profiler'
  gem 'web-console'
end

# Testing Tools
group :test do
  gem 'capybara'
  gem 'database_cleaner-active_record'
  gem 'pundit-matchers'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'stackprof'
  gem 'test-prof'
  gem 'webdrivers'
end

# Development & Testing
group :development, :test do
  gem 'avo_upgrade'
  gem 'brakeman', require: false
  gem 'bundle-audit'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'fuubar'
  gem 'letter_opener_web'
  gem 'overcommit', require: false
  gem 'parallel_tests'
  gem "rspec-rails"
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'shoulda-matchers', '~> 6.0'
  gem 'simplecov'
  gem "spring"
  gem 'vcr'
  gem 'webmock'
end
