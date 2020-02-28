# frozen_string_literal: true

source 'https://rubygems.org'

gem 'exception_notification'
gem 'hashie' # Used in the setting object, allows access by object and hash notation
gem 'inline_svg' # Lets us easily inline our SVGs to allow styling - supports the rails asset pipeline
gem 'json_api_client', github: 'sanger/json_api_client' # Communications with JSON APIs, allows us to begin migration to the new Sequencescape API
gem 'pmb-client', '0.1.0', github: 'sanger/pmb-client'
gem 'puma'
gem 'rails'
gem 'rake'
gem 'sanger_barcode_format', github: 'sanger/sanger_barcode_format', branch: 'development'
gem 'sequencescape-client-api', require: 'sequencescape' # Older Sequencescape API
gem 'state_machines'
gem 'webpacker'

group :test do
  gem 'capybara' # Interface for integration tests
  gem 'capybara-selenium' # Browser driver for integration tests
  gem 'factory_bot' # Generate models and JSON easily in tests
  gem 'guard-rspec', require: false
  gem 'launchy' # Used by capybara for e.g. save_and_open_screenshot
  gem 'rails-controller-testing'
  gem 'rspec-json_expectations'
  gem 'rspec-rails'
  gem 'simplecov', require: false
  gem 'simplecov-json', require: false
  gem 'webdrivers', require: false # Keep webdriver in sync with chrome to prevent CI failures
  gem 'webmock'
end

group :development, :test do
  gem 'bootstrap'
  gem 'coffee-rails', require: false
  gem 'jquery-rails'
  gem 'jquery-ui-rails' # We use the sortable component of jquery ui
  gem 'sass-rails'
  gem 'select2-rails'
  gem 'uglifier'
end

group :development do
  gem 'pry'
  gem 'pry-byebug'
  gem 'rack-mini-profiler' # MiniProfiler allows you to see the speed of a request on the page.
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'travis'
  gem 'web-console'
end
