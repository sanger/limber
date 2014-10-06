source 'http://rubygems.org'

gem 'compass', '>= 0.11.1'
gem 'formtastic', '~>1.2.3'
gem 'rails', '~>3.0.19'
gem 'rake', '~>0.9.2'
gem 'state_machine', '~>1.0.1'
gem 'hashie', '~>1.0.0'
gem 'exception_notification'

gem 'sequencescape-client-api', '>= 0.2.3',
  :git     => 'git+ssh://git@github.com/sanger/sequencescape-client-api.git',
  :branch  => 'production',
  :require => 'sequencescape'
gem 'sanger_barcode', '>= 0.2.0',
  :git     => 'git+ssh://git@github.com/sanger/sanger_barcode.git'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :test do
  gem 'capybara'
  gem 'cucumber-rails', :require => false
  gem 'launchy'
end
group :development do
  gem 'ruby-debug19', :require => 'ruby-debug'
end

group :deployment do
  gem 'thin'
  gem "psd_logger", :git => "git+ssh://git@github.com/sanger/psd_logger.git"
end
