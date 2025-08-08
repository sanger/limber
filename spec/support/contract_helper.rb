# frozen_string_literal: true

# Fake the web connections so we don't trash anything
require 'webmock/rspec'

module ContractHelper
  class StubRequestBuilder
    include WebMock::API
    include WebMock::Matchers

    def initialize(root_directory)
      @root = File.split(File.expand_path(root_directory))
    end

    # rubocop:todo Lint/MixedRegexpCaptureTypes
    # rubocop:todo Lint/MissingCopEnableDirective
    # rubocop:todo Layout/LineLength
    # rubocop:enable Lint/MissingCopEnableDirective
    REQUEST_REGEXP =
      %r{ # rubocop:todo Lint/MixedRegexpCaptureTypes # rubocop:todo Lint/MixedRegexpCaptureTypes # rubocop:todo Lint/MixedRegexpCaptureTypes
    # rubocop:enable Layout/LineLength
      (?<eol>       \r\n|\r|\n){0}
      (?<verb>      GET|PUT|POST|DELETE){0}
      (?<path>      /[^\s]*){0}
      (?<body>      .+){0}
      (?<header>    [^:\r\n]+:[^\r\n]+){0}
      (?<headers>   \g<header>(\g<eol>\g<header>)*){0}

      \g<verb>\s+\g<path>\s+HTTP/1.1\g<eol>
      \g<headers>\g<eol>
      (\g<eol>\g<body>?)?
    }mx

    # rubocop:enable Lint/MixedRegexpCaptureTypes
    # rubocop:todo Metrics/AbcSize
    def request(contract_name)
      contract(contract_name) do |file|
        match =
          REQUEST_REGEXP.match(file.read) ||
          raise(StandardError, "Invalidly formatted request in #{contract_name.inspect}")

        @http_verb = match[:verb].downcase.to_sym
        @url = "http://example.com:3000#{match[:path]}"
        @conditions = {}
        @conditions[:headers] = Hash[*match[:headers].split(/\r?\n/).map { |l| l.split(':') }.flatten.map(&:strip)]
        @conditions[:body] = Yajl::Encoder.encode(Yajl::Parser.parse(match[:body])) if match[:body].present?
      end
    end

    # rubocop:enable Metrics/AbcSize

    def response(contract_name, times: nil)
      contract(contract_name) do |file|
        @times = times
        @content = file.read
      end
    end

    def inject_into(spec)
      builder = self
      spec.before(:each) { builder.send(:setup_request_and_response_mock) }
      spec.after(:each) { builder.send(:validate_request_and_response_called, self) }
    end

    def setup_request_and_response_mock
      stub_request(@http_verb, @url).with(@conditions).to_return(@content)
    end

    private

    def contract(contract_name, &)
      path = @root.dup
      until path.empty?
        filename = File.join(path, 'contracts', "#{contract_name}.txt")
        return File.open(filename, 'r', &) if File.file?(filename)

        path.pop
      end
      raise StandardError, "Cannot find contract #{filename.inspect} anywhere within #{@root.inspect}"
    end

    def validate_request_and_response_called(scope)
      if @times == :any
        # Nothing
      elsif @times
        scope.expect(a_request(@http_verb, @url).with(@conditions)).to have_been_made.times(@times)
      else
        scope.expect(a_request(@http_verb, @url).with(@conditions)).to have_been_made.at_least_once
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def expect_request_from(request_filename, &)
      stubbed_request = StubRequestBuilder.new(File.join(File.dirname(__FILE__), %w[.. contracts]))
      stubbed_request.request(request_filename)
      stubbed_request.instance_eval(&)
      stubbed_request.inject_into(self)
    end

    def has_a_working_api(times: :any)
      expect_request_from('retrieve-api-root') { response('api-root', times:) }
      let(:api) do
        Sequencescape::Api.new(
          url: 'http://example.com:3000/',
          cookie: nil,
          namespace: Limber,
          authorisation: 'testing'
        )
      end
    end
  end
end

RSpec.configure { |config| config.include ContractHelper }
