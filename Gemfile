# frozen_string_literal: true

source 'https://rubygems.org'

group :default do
  gem 'bootsnap'
  gem 'rails'
  # Lets us easily inline our svg to allow styling. Supports the rails asset pipeline.
  gem 'inline_svg'

  gem 'exception_notification'
  gem 'rake'
  gem 'state_machines'
  gem 'webpacker'

  # Adds easy conversions between units
  gem 'ruby-units'

  # Used in the setting object, allows access by object and hash notation.
  gem 'hashie'

  # Communications with JSON APIs, allows us to begin migration to the new Sequencescape API
  gem 'json_api_client', github: 'sanger/json_api_client', branch: 'merge_upstream'

  # Older Sequencescape API
  gem 'sequencescape-client-api', path: '/Users/emr/projects/sequencescape-client-api', require: 'sequencescape'
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
  gem 'rspec-rails'
  gem 'simplecov', require: false
  # Keep webdriver in sync with chrome to prevent frustrating CI failures
  gem 'webdrivers', require: false
  gem 'webmock'
end

group :development, :test do
  gem 'uglifier'
  # Bootstrap is a css framework
  # Pinning to v4 as bootstrap 5 drops compatibility with the latest versions of chrome and FF on XP
  # Some lab machines are locked to XP due to vendor compatibility
  gem 'bootstrap', '~>4'
  # gem 'coffee-rails', require: false
  # Use jquery as the JavaScript library
  gem 'jquery-rails'
  gem 'sass-rails'
  gem 'select2-rails'
  # We use the sortable component of jquery ui
  gem 'jquery-ui-rails'
end

group :development do
  gem 'guard-rspec', require: false
  gem 'pry'
  gem 'pry-byebug'
  gem 'web-console'
  # MiniProfiler allows you to see the speed of a request conveniently on the page.
  gem 'rack-mini-profiler'
  # Ruby jard is a ruby debugger, buit on top of pry and byebug. Invoke it
  # with jard
  # gem 'ruby_jard'
  gem 'yard'
end

group :lint do
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end
