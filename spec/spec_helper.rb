# frozen_string_literal: true

# https://github.com/simplecov-ruby/simplecov#getting-started

require 'simplecov'
require 'simplecov_json_formatter'
require 'simplecov-lcov'
SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov::Formatter::LcovFormatter.config.single_report_path = 'lcov.info'
SimpleCov.formatters =
  SimpleCov::Formatter::MultiFormatter.new(
    [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::JSONFormatter, SimpleCov::Formatter::LcovFormatter]
  )
SimpleCov.start :rails

# Previous content of test helper now starts here

# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

require 'factory_bot'
require_relative 'support/contract_helper'
require_relative 'support/api_url_helper'
require_relative 'support/feature_helpers'
require_relative 'support/robot_helpers'
require_relative 'support/time_helpers'
require_relative 'support/with_pmb_stubbed'
require 'rspec/json_expectations'
require 'capybara/rspec'
require 'webmock/rspec'
require 'selenium/webdriver'
require 'csv'

begin
  require 'pry'
rescue LoadError
  # We don't have pry. We're probably on CI.
  nil
end

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable_gpu')
  options.add_argument('--window-size=1600,3200')
  options.add_argument('--no-sandbox')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = ENV.fetch('JS_DRIVER', 'headless_chrome').to_sym
Capybara.default_max_wait_time = 3
Capybara.server = :puma, { Silent: true }

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = 'spec/examples.txt'

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  config.include FactoryBot::Syntax::Methods
  config.include FeatureHelpers, type: :feature

  config.before(:suite) do
    Rails.application.load_tasks

    Rake::Task['assets:precompile'].invoke

    FactoryBot.find_definitions
    Settings.robots = {}
    Settings.transfer_templates = {
      'Custom pooling' => 'custom-pooling',
      'Pool wells based on submission' => 'custom-transfer-template',
      'Transfer between specific tubes' => 'transfer-between-specific-tubes',
      'Transfer columns 1-12' => 'transfer-1-12',
      'Transfer from tube to tube by submission' => 'tube-to-tube-by-sub',
      'Transfer wells to MX library tubes by submission' => 'transfer-to-mx-tubes-on-submission',
      'Whole plate to tube' => 'whole-plate-to-tube'
    }
    YAML
      .parse_file(Rails.root.join('config/label_templates.yml'))
      .to_ruby
      .tap do |label_templates|
        Settings.default_pmb_templates = label_templates['defaults_by_printer_type']['pmb_templates']
        Settings.default_sprint_templates = label_templates['defaults_by_printer_type']['sprint_templates']
        Settings.default_printer_type_names = label_templates['defaults_by_printer_type']['printer_type_names']
      end
  end

  config.before(:each) do
    # We need to be able to talk to capybara.
    # Unfortunately this means the library, not the animal.
    WebMock.disable_net_connect!(allow_localhost: true)
    WebMock.reset!
    if Capybara.current_session.driver.respond_to?(:resize_window)
      Capybara.current_session.driver.resize_window(1400, 1400)
    end

    # Wipe out existing purposes
    Settings.purposes = {}
    Settings.pipelines = PipelineList.new
    Settings.poolings = {}
  end

  factory_bot_results = {}
  config.before(:suite) do
    ActiveSupport::Notifications.subscribe('factory_bot.run_factory') do |_name, start, finish, _id, payload|
      factory_name = payload[:name]
      strategy_name = payload[:strategy].to_s
      time_taken = finish - start
      factory_bot_results[factory_name] ||= {}
      factory_bot_results[factory_name][strategy_name] ||= []
      factory_bot_results[factory_name][strategy_name] << time_taken
    end
  end

  config.after(:suite) do
    unused_factories = FactoryBot.factories.map(&:name)
    CSV.open('tmp/factories.csv', 'wb') do |csv|
      csv << ['Factory', 'Strategy', 'Called', 'Total Time (s)', 'Avg Time (s)']
      factory_bot_results.each do |factory, strategy_details|
        strategy_details.each do |strategy, times|
          unused_factories.delete(factory)
          csv << [factory, strategy, times.length, times.sum, times.sum / times.length]
        end
      end
      unused_factories.each { |factory| csv << [factory, 'UNUSED', 0, 0, 0] }
    end
    puts "\n📊 Output factory statistics to tmp/factories.csv"
  end
end
