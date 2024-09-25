# frozen_string_literal: true

source 'https://rubygems.org'

group :default do
  gem 'bootsnap'
  gem 'rails'

  gem 'exception_notification'
  gem 'rake'
  gem 'state_machines'

  # Build dependencies
  gem 'vite_rails'
  gem 'vite_ruby'

  # Adds easy conversions between units
  gem 'ruby-units'

  # Used in the setting object, allows access by object and hash notation.
  gem 'hashie'

  # Communications with JSON APIs, allows us to begin migration to the new Sequencescape API
  gem 'json_api_client', github: 'sanger/json_api_client', branch: 'v1.21.0a'

  # Older Sequencescape API
  gem 'sequencescape-client-api', require: 'sequencescape'

  # Speed up json encoding/decoding with oj
  gem 'oj'

  gem 'pmb-client', '0.1.0', github: 'sanger/pmb-client'
  gem 'sprint_client'

  gem 'puma'
  gem 'sanger_barcode_format', github: 'sanger/sanger_barcode_format', branch: 'development'
end
# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :test do
  gem 'capybara' # Interface for integration tests
  gem 'capybara-selenium' # Browser driver for integration tests
  gem 'factory_bot' # Generate models and json easily in tests
  gem 'launchy' # Used by capybara for eg. save_and_open_screenshot
  gem 'rails-controller-testing'
  gem 'rspec-json_expectations'
  gem 'rspec-rails', '6.1.3'
  gem 'selenium-webdriver', '~> 4.1', require: false
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
  gem 'webmock'
end

group :development do
  gem 'guard-rspec', require: false
  gem 'pry'
  gem 'pry-byebug'
  gem 'web-console'

  # MiniProfiler allows you to see the speed of a request conveniently on the page.
  gem 'rack-mini-profiler'
  gem 'yard'
end

group :lint do
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false

  # Ruby dependencies specifically requested by prettier/plugin-ruby v4
  # https://github.com/prettier/plugin-ruby
  gem 'prettier_print', require: false
  gem 'syntax_tree', require: false
  gem 'syntax_tree-haml', require: false
  gem 'syntax_tree-rbs', require: false
end
