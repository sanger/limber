# frozen_string_literal: true

require './spec/support/contract_helper.rb'
require 'pry'

namespace :test do
  namespace :factories do
    desc 'Lint the factories'
    task lint: :environment do
      require 'webmock'
      include WebMock::API

      WebMock.enable!
      # We currently use mocks in the factories to handle building API
      # objects. We should look at better ways of handling this, but until
      # then we enable mocks while linting.
      RSpec::Mocks.with_temporary_scope do
        api = ContractHelper::StubRequestBuilder.new(File.join(File.dirname(__FILE__), %w[.. .. spec contracts]))
        api.request('retrieve-api-root')
        api.response('api-root', times: :any)
        api.setup_request_and_response_mock

        FactoryBot.find_definitions

        puts 'Linting factories...'
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          FactoryBot.lint verbose: ENV['VERBOSE'].present?
        rescue FactoryBot::InvalidFactoryError => e
          puts e.message
          exit 1
        end

        complete = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        puts "Done in #{complete - starting}"
      end
      WebMock.disable!
    end
  end
end
