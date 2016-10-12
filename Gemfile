source 'http://rubygems.org'

gem 'formtastic'
# Provides some css helpers
# Deprecate!
gem 'compass-rails'
gem 'rails'
gem 'sass-rails'
gem 'uglifier'

# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', :require => false

gem 'rake'
gem 'state_machine', '~>1.0.1'
gem 'hashie', '~>1.0.0'
gem 'exception_notification'

gem 'sequencescape-client-api', '>= 0.3.0',
  # Should be switched back to sanger + production for deployment
  :github  => 'jamesGlover/sequencescape-client-api',
  :branch  => 'with_rails_5_support',
  :require => 'sequencescape'
gem 'sanger_barcode', '>= 0.2.1',
  :git     => 'git+ssh://git@github.com/sanger/sanger_barcode.git'

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
