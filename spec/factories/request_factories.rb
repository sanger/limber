# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :request, class: Sequencescape::Api::V2::Request, traits: [:uuid] do
    transient do
      request_type { create :request_type }
      pcr_cycles 10
      primer_panel nil
    end

    skip_create
    role 'WGS'
    priority 0
    state 'pending'
    options do
      {
        'pcr_cycles' => pcr_cycles
      }
    end

    after(:build) do |request, evaluator|
      RSpec::Mocks.allow_message(request, :request_type).and_return(evaluator.request_type)
      RSpec::Mocks.allow_message(request, :primer_panel).and_return(evaluator.primer_panel)
    end

    factory :library_request do
      transient do
        request_type { create :library_request_type }
      end

      factory :gbs_library_request do
        transient do
          primer_panel
        end
      end
    end

    factory :mx_request do
      transient do
        request_type { create :mx_request_type }
      end
    end
  end

  factory :primer_panel, class: Sequencescape::Api::V2::PrimerPanel do
    skip_create

    name 'example panel'
    programs('pcr 1' => { 'name' => 'example program', 'duration' => 45 },
             'pcr 2' => { 'name' => 'other program', 'duration' => 20 })
  end

  factory :request_type, class: Sequencescape::Api::V2::RequestType do
    skip_create
    name 'Request Type'
    key 'request_type'
    for_multiplexing false

    factory :library_request_type do
      name 'Limber WGS'
      key 'limber_wgs'
    end

    factory :mx_request_type do
      name 'Limber Multiplexing'
      key 'limber_multiplexing'
      for_multiplexing true
    end
  end
end
