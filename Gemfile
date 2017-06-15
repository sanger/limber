# frozen_string_literal: true

source 'https://rubygems.org'

gem 'formtastic'

gem 'coffee-rails'
gem 'rails'
gem 'sass-rails'
gem 'uglifier'

# Provides some css helpers
# Deprecate!
gem 'compass-rails'

# Required for bootstrap tooltips
gem 'rails-assets-tether', '>= 1.1.0'
# Bootstrap is a css framework
gem 'bootstrap'

# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', require: false

# Lets us easily inline our svg to allow styling. Supports the rails asset pipeline.
gem 'inline_svg'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# We use the sortable component of jquery ui
gem 'jquery-ui-rails'

gem 'rake'
gem 'state_machines'
# Used in the setting object, allows access by object and hash notation.
gem 'exception_notification'
gem 'hashie'

gem 'sequencescape-client-api', '>= 0.3.3',
    github: 'sanger/sequencescape-client-api',
    branch: 'rails_4',
    require: 'sequencescape'

gem 'pmb-client', '0.1.0', github: 'sanger/pmb-client'

gem 'sanger_barcode_format', github: 'sanger/sanger_barcode_format', branch: 'development'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :test do
  gem 'capybara'
  gem 'factory_girl' # Generate models and json easily in tests
  gem 'guard-rspec', require: false
  gem 'launchy' # Used by capybara for eg. save_and_open_screenshot
  gem 'poltergeist'
  gem 'rails-controller-testing'
  gem 'rspec-json_expectations'
  gem 'rspec-rails'
  gem 'webmock'
end

group :development do
  gem 'pry'
  gem 'pry-byebug'
  gem 'rubocop', require: false
  gem 'web-console'
  # MiniProfiler allows you to see the speed of a request conveniently on the page.
  gem 'rack-mini-profiler'
end

group :deployment do
  gem 'psd_logger', github: 'sanger/psd_logger'
  gem 'thin'
end
