source 'http://rubygems.org'

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
gem 'therubyracer', :require => false

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
  :github  => 'jamesGlover/sequencescape-client-api',
  :branch  => 'with_rails_5_support',
  :require => 'sequencescape'
gem 'sanger_barcode', '>= 0.2.1',
  :git     => 'git+ssh://git@github.com/sanger/sanger_barcode.git'
gem 'sanger_barcodeable', path: '../barcode_gem'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :test do
  gem 'capybara'
  gem 'rspec'
  gem 'launchy'
end
group :development do
  gem 'pry'
  gem 'rubocop', require: false
  gem 'web-console'
end

group :deployment do
  gem 'thin'
  gem "psd_logger", :git => "git+ssh://git@github.com/sanger/psd_logger.git"
end
