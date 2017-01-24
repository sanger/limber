source 'https://rubygems.org'

gem 'formtastic'

gem 'rails'
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'

# Provides some css helpers
# Deprecate!
gem 'compass-rails'

# Required for bootstrap tooltips
gem 'rails-assets-tether', '>= 1.1.0'
gem 'bootstrap'

# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', require: false

# Lets us easily inline our svg to allow styling. Supports the asset pipeline.
gem 'inline_svg'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# We use the sortable component of jquery ui
gem 'jquery-ui-rails'

gem 'rake'
gem 'state_machines'
gem 'hashie'
gem 'exception_notification'

gem 'sequencescape-client-api', '>= 0.3.0',
  # Should be switched back to sanger + production for deployment
  # github: 'JamesGlover/sequencescape-client-api',
  # branch: 'add_limber_needs',
  path: '../sequencescape-client-api',
  require: 'sequencescape'

gem 'pmb-client', '0.1.0', github: 'sanger/pmb-client'

gem 'sanger_barcode', '>= 0.2.1',
  git: 'git+ssh://git@github.com/sanger/sanger_barcode.git'

gem 'sanger_barcode_format', git: 'git@github.com:sanger/sanger_barcode_format.git', branch: 'development'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'rspec-rails'
  gem 'rspec-json_expectations'
  gem 'launchy'
  gem 'factory_girl'
  gem 'webmock'
  gem 'rails-controller-testing'
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
  gem 'thin'
  gem "psd_logger", git: 'git+ssh://git@github.com/sanger/psd_logger.git'
end
